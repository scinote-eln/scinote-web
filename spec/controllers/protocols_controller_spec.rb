# frozen_string_literal: true

require 'rails_helper'

describe ProtocolsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { team_role: :owner }
  let(:repository_protocol) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:repository_protocol_2) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:published_protocol) { create :protocol, :in_repository_published_original, team: team, added_by: user }
  let(:draft_protocol) { create :protocol, :in_repository_draft, team: team, added_by: user, parent: published_protocol, version_number: 2 }
  let(:archived_protocol) { create :protocol, :in_repository_published_original, team: team, added_by: user, archived: true, archived_by: user, archived_on: Time.now }

  describe 'GET index' do
    let(:action) { get :index, params: { team_id: team.id }, format: :json }
    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["data"]).to be_an(Array)
    end
  end

  describe 'GET versions_modal' do
    let(:params) { { id: repository_protocol.id } }
    let(:action) { get :versions_modal, params: params, format: :json }

    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET linked_children' do
    let(:linked_protocol) do
      create :protocol, :linked_to_repository, name: ' test protocol',
                                               my_module: my_module,
                                               parent: published_protocol,
                                               team: team,
                                               added_by: user
    end
    let(:action) { get :linked_children, params: { id: published_protocol.id }, format: :json }

    it 'returns a successful response' do
      linked_protocol
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["data"]).to be_an(Array)
      expect(JSON.parse(response.body)["data"].length).to eq(1)
    end
  end

  describe 'GET versions_list' do
    let(:params) { { id: published_protocol.id } }
    let(:action) { get :versions_list, params: params, format: :json }
    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["versions"]).to be_an(Array)
      expect(JSON.parse(response.body)["versions"].length).to eq(1)
    end
  end

  describe 'POST publish' do
    let(:params) { { id: repository_protocol.id } }
    let(:action) { post :publish, params: params, format: :json }
    it 'calls create activity for publishing protocol' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :protocol_template_published)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    it 'changes protocol status to published' do
      action
      expect(repository_protocol.reload.protocol_type).to eq('in_repository_published_original')
    end
  end

  describe 'POST destroy_draft' do
    let(:params) { { id: draft_protocol.id } }
    let(:action) { post :destroy_draft, params: params, format: :json }
    it 'calls create activity for deleting protocol draft' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :protocol_template_draft_deleted)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'POST update_name' do
    let(:params) do
      { id: repository_protocol.id,
        protocol: { name: 'Updated Protocol Name' } }
    end
    let(:action) { post :update_name, params: params, format: :json }
    it 'calls create activity for updating protocol name' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :edit_protocol_name_in_repository)))
      action
    end
    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'POST update_description_locked' do
    before { allow(Protocol).to receive(:content_locking_enabled?).and_return(true) }

    let(:params) do
      { id: repository_protocol.id,
        protocol: { description_locked: true } }
    end
    let(:action) { post :update_description_locked, params: params, format: :json }

    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
    end

    it 'locks the protocol description' do
      action
      expect(repository_protocol.reload.description_locked).to be true
    end

    context 'when protocol draft cannot be managed' do
      let(:params) do
        { id: published_protocol.id,
          protocol: { description_locked: true } }
      end

      it 'returns a forbidden response' do
        action
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not lock the protocol description' do
        action
        expect(published_protocol.reload.description_locked).to be false
      end
    end

    context 'when protocol content locking is disabled' do
      before { allow(Protocol).to receive(:content_locking_enabled?).and_return(false) }

      it 'returns a forbidden response' do
        action
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not lock the protocol description' do
        action
        expect(repository_protocol.reload.description_locked).to be false
      end
    end
  end

  describe 'POST update_authors' do
    let(:params) do
      { id: repository_protocol.id,
        protocol: { authors: 'New Author' } }
    end
    let(:action) { post :update_authors, params: params, format: :json }
    it 'calls create activity for updating protocol authors' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :edit_authors_in_protocol_repository)))
      action
    end
    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'POST archive' do
    let(:params) { { protocol_ids: [published_protocol.id] } }
    let(:action) { post :archive, params: params, format: :json }

    it 'calls create activity for archiving protocols' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :archive_protocol_in_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    it 'changes protocol status to archived' do
      action
      expect(published_protocol.reload.archived).to be true
    end
  end

  describe 'POST restore' do
    let(:params) { { protocol_ids: [archived_protocol.id] } }
    let(:action) { post :restore, params: params, format: :json }
    it 'calls create activity for restoring protocols' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :restore_protocol_in_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    it 'changes protocol status to unarchived' do
      action
      expect(archived_protocol.reload.archived).to be false
    end
  end

  describe 'GET show' do
    let(:params) { { id: repository_protocol.id } }
    let(:action) { get :show, params: params, format: :json }
    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["data"]).to include("id" => repository_protocol.id.to_s)
    end
  end

  describe 'POST create' do
    let(:params) do
      {
        protocol: {
          name: 'New Protocol',
          description: 'Protocol Description',
          protocol_type: 'in_repository_draft'
        },
        team_id: team.id
      }
    end
    let(:action) { post :create, params: params, format: :json }
    it 'calls create activity for creating protocol' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :create_protocol_in_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    it 'creates a new protocol' do
      expect { action }
        .to(change { Protocol.count }.by(1))
    end
  end

  describe 'POST delete_steps' do
    let(:params) { { id: repository_protocol.id } }
    let(:action) { post :delete_steps, params: params, format: :json }
    let(:step1) { create :step, protocol: repository_protocol, position: 1 }
    let(:step2) { create :step, protocol: repository_protocol, position: 2 }

    before do
      step1
      step2
    end

    it 'calls create activity for deleting steps' do
      2.times do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :delete_step_in_protocol_repository)))
      end

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count }.by(2))
    end
  end

  describe 'POST clone' do
    let(:params) { { protocol_ids: repository_protocol.id, team_id: team.id } }
    let(:action) { post :clone, params: params, format: :json }
    it 'calls create activity for cloning protocol' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :copy_protocol_in_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    it 'clones the protocol correctly' do
      action
      cloned_protocol = Protocol.order(:created_at).last
      expect(cloned_protocol.name).to eq(repository_protocol.name)
      expect(cloned_protocol.description).to eq(repository_protocol.description)
    end
  end

  describe 'POST copy_to_repository' do
    let(:protocol_in_task) do
      create :protocol, name: 'test protocol', my_module: my_module
    end
    let(:params) { { id: protocol_in_task.id, team_id: team.id, protocol: { name: 'test' } } }
    let(:action) { post :copy_to_repository, params: params, format: :json }

    it 'calls create activity for copying protocol to repository' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :task_protocol_save_to_template)))
      action
    end
    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count }.by(1))
    end

    it 'copies the protocol to repository correctly' do
      action
      copied_protocol = Protocol.order(:created_at).last
      expect(copied_protocol.name).to eq('test' )
      expect(copied_protocol.description).to eq(protocol_in_task.description)
      expect(copied_protocol.protocol_type).to eq('in_repository_draft')
    end

    context 'when the description is locked' do
      let(:protocol_in_task) do
        create :protocol, name: 'test protocol', my_module: my_module, description_locked: true
      end

      it 'propagates description_locked to the copied protocol' do
        action
        copied_protocol = Protocol.order(:created_at).last
        expect(copied_protocol.description_locked).to be true
      end
    end
  end

  describe 'POST save_as_draft' do
    let(:params) { { id: published_protocol.id } }
    let(:action) { post :save_as_draft, params: params, format: :json }
    it 'calls create activity for saving protocol as draft' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :protocol_template_draft_created)))
      action
    end
    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    it 'creates a draft version of the protocol' do
      expect { action }
        .to(change { Protocol.where(parent_id: published_protocol.id).count }.by(1))
    end
  end

  describe 'GET export from MyModule' do
    let(:params) { { protocol_ids: [repository_protocol.id], my_module_id: my_module.id } }
    let!(:step1) { create :step, protocol: repository_protocol, position: 1 }
    let!(:step2) { create :step, protocol: repository_protocol, position: 2 }
    let(:action) { get :export, params: params }

    it 'calls create activity for exporting protocols' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :export_protocol_from_task)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count }.by(1))
      expect(Activity.last.subject_type).to eq 'MyModule'
    end
  end

  describe 'POST import' do
    let(:params) do
      {
        team_id: team.id,
        type: 'public',
        # protocol: file_fixture('files/my_test_protocol.eln',
        #   'application/json'),
        # Not sure where should I attache file?
        protocol: {
          name: 'my_test_protocol',
          description: 'description',
          authors: 'authors',
          elnVersion: '1.0',
        }
      }
    end

    let(:action) { post :import, params: params, format: :json }

    it 'calls create activity for importing protocols' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :import_protocol_in_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PATCH description' do
    let(:params) do
      {
        id: repository_protocol.id,
        protocol: {
          description: 'description'
        }
      }
    end
    let(:action) { patch :update_description, params: params, format: :json }
    it 'calls create activity for updating description' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :edit_description_in_protocol_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PATCH update_keywords' do
    let(:params) do
      { id: repository_protocol.id, keywords: ['keyword-1', 'keyword-2'] }
    end
    let(:action) { patch :update_keywords, params: params, format: :json }

    it 'calls create activity for updating keywords' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :edit_keywords_in_protocol_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  context 'update protocol' do
    let(:protocol_repo) do
      create :protocol, :in_repository_published_original, name: ' test protocol',
                                               team: team,
                                               added_by: user
    end
    let(:protocol) do
      create :protocol, :linked_to_repository, name: ' test protocol',
                                               my_module: my_module,
                                               parent: protocol_repo,
                                               team: team,
                                               added_by: user
    end
    let(:params) { { id: protocol.id } }

    describe 'POST revert' do
      let(:action) { post :revert, params: params, format: :json }

      it 'calls create activity for updating protocol in task from repository' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :update_protocol_in_task_from_repository)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'POST load_from_repository' do
    let(:protocol_source) do
      create :protocol, :in_repository_published_original, team: team, added_by: user
    end
    let(:protocol) { create :protocol, team: team, added_by: user, my_module: my_module }
    let(:params) do
      { source_id: protocol_source.id, id: protocol.id }
    end
    let(:action) { post :load_from_repository, params: params, format: :json }

    it 'calls create activity for loading protocol to task from repository' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :load_protocol_to_task_from_repository_replace)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'POST unlink' do
    let(:protocol_repo) do
      create :protocol, :in_repository_published_original, name: ' test protocol',
                                               team: team,
                                               added_by: user
    end
    let(:protocol) do
      create :protocol, :linked_to_repository, name: ' test protocol',
                                               my_module: my_module,
                                               parent: protocol_repo,
                                               team: team,
                                               added_by: user
    end
    let(:params) { { id: protocol.id } }
    let(:action) { post :unlink, params: params, format: :json }

    it 'unlinks the protocol correctly' do
      action
      expect(protocol.reload.parent_id).to be_nil
    end
  end

  describe 'POST update_from_parent' do
   let(:protocol_repo) do
      create :protocol, :in_repository_published_original, name: ' test protocol',
                                               team: team,
                                               added_by: user
    end
    let(:protocol) do
      create :protocol, :linked_to_repository, name: ' test protocol',
                                               my_module: my_module,
                                               parent: protocol_repo,
                                               team: team,
                                               added_by: user
    end
    let(:params) { { id: protocol.id } }
    let(:action) { post :update_from_parent, params: params, format: :json }

    it 'calls create activity for updating protocol in task from repository' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :update_protocol_in_task_from_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

  end

  describe 'GET unlink_modal' do
    let(:protocol_repo) do
      create :protocol, :in_repository_published_original, name: ' test protocol',
                                               team: team,
                                               added_by: user
    end
    let(:protocol) do
      create :protocol, :linked_to_repository, name: ' test protocol',
                                               my_module: my_module,
                                               parent: protocol_repo,
                                               team: team,
                                               added_by: user
    end
    let(:params) { { id: protocol.id } }
    let(:action) { get :unlink_modal, params: params, format: :json }

    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET revert_modal' do
    let(:protocol_repo) do
      create :protocol, :in_repository_published_original, name: ' test protocol',
                                               team: team,
                                               added_by: user
    end
    let(:protocol) do
      create :protocol, :linked_to_repository, name: ' test protocol',
                                               my_module: my_module,
                                               parent: protocol_repo,
                                               team: team,
                                               added_by: user
    end
    let(:params) { { id: protocol.id } }
    let(:action) { get :revert_modal, params: params, format: :json }

    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET update_from_parent_modal' do
    let(:protocol_repo) do
      create :protocol, :in_repository_published_original, name: ' test protocol',
                                               team: team,
                                               added_by: user
    end
    let(:protocol) do
      create :protocol, :linked_to_repository, name: ' test protocol',
                                               my_module: my_module,
                                               parent: protocol_repo,
                                               team: team,
                                               added_by: user
    end
    let(:params) { { id: protocol.id } }
    let(:action) { get :update_from_parent_modal, params: params, format: :json }

    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET load_from_repository_modal' do
    let(:params) { { id: my_module.protocol.id } }
    let(:action) { get :load_from_repository_modal, params: params, format: :json }

    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET list_published_protocol_templates' do
    let(:params) { { id: my_module.protocol.id } }
    let(:action) { get :list_published_protocol_templates, params: params, format: :json }

    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET protocol_status_bar' do
    let(:params) { { id: published_protocol.id } }
    let(:action) { get :protocol_status_bar, params: params, format: :json }

    it 'returns a successful response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end


end

describe ProtocolsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { team_role: :owner }

  let(:other_user) { create :user }
  let(:repository_protocol) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:published_protocol) { create :protocol, :in_repository_published_original, team: team, added_by: user }
  let(:draft_protocol) do
    create :protocol, :in_repository_draft, team: team, added_by: user, parent: published_protocol, version_number: 2
  end
  let(:foreign_protocol) { create :protocol, :in_repository_draft, team: team, added_by: other_user }
  let(:foreign_published_protocol) do
    create :protocol, :in_repository_published_original, team: team, added_by: other_user
  end
  let(:linked_protocol) do
    create :protocol, :linked_to_repository, my_module: my_module, parent: published_protocol, team: team, added_by: user
  end

  def json
    JSON.parse(response.body)
  end

  def downgrade_my_module_role_to_viewer
    UserAssignment.where(user: user, assignable: [my_module, experiment, project]).update_all(user_role_id: viewer_role.id)
  end

  describe 'GET index' do
    it 'renders the html index with breadcrumbs' do
      get :index, params: { team_id: team.id }, format: :html

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
      expect(assigns(:breadcrumbs_items).first[:label]).to eq I18n.t('breadcrumbs.protocols')
    end

    it 'prefixes breadcrumbs with archived label in archived view mode' do
      get :index, params: { team_id: team.id, view_mode: 'archived' }, format: :html

      expect(assigns(:breadcrumbs_items).first[:label]).to start_with(I18n.t('labels.archived'))
    end

    it 'returns only readable protocols for non-managers' do
      repository_protocol
      foreign_protocol
      allow(controller).to receive(:can_manage_team?).and_return(false)

      get :index, params: { team_id: team.id }, format: :json

      ids = json['data'].map { |p| p['id'].to_i }
      expect(ids).to include(repository_protocol.id)
      expect(ids).not_to include(foreign_protocol.id)
    end

    it 'returns 403 when user cannot read the team' do
      allow(controller).to receive(:can_read_team?).and_return(false)

      get :index, params: { team_id: team.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET versions_modal' do
    it 'returns draft and published versions for a published original' do
      draft_protocol

      get :versions_modal, params: { id: published_protocol.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['draft']).to be_present
      expect(json['versions'].length).to eq 1
    end

    it 'returns 403 for a published version that is not the original' do
      published_version = create :protocol, :in_repository_published_version,
                                 team: team, added_by: user, parent: published_protocol, version_number: 2

      get :versions_modal, params: { id: published_version.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 when user cannot read the protocol' do
      get :versions_modal, params: { id: foreign_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET print' do
    it 'renders print template with print layout' do
      get :print, params: { id: repository_protocol.id }

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(layout: 'protocols/print')
    end
  end

  describe 'GET linked_children' do
    it 'returns children linked to a specific version' do
      linked_protocol

      get :linked_children, params: { id: published_protocol.id, version: 1 }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['data'].length).to eq 1
      expect(json['data'].first['my_module_name']).to eq my_module.name
      expect(json['total_pages']).to eq 1
    end

    it 'returns 403 when user cannot read protocol and does not manage the team' do
      allow(controller).to receive(:can_manage_team?).and_return(false)

      get :linked_children, params: { id: foreign_published_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST publish' do
    it 'returns protocol url when published from show view' do
      post :publish, params: { id: repository_protocol.id, view: 'show', version_comment: 'first' }, format: :json

      expect(json['url']).to eq protocol_path(repository_protocol)
      expect(repository_protocol.reload.version_comment).to eq 'first'
      expect(repository_protocol.published_by).to eq user
    end

    it 'publishes a draft of a published protocol as a version' do
      post :publish, params: { id: draft_protocol.id, view: 'show' }, format: :json

      expect(draft_protocol.reload).to be_in_repository_published_version
    end

    it 'rolls back and sets an error flash when publishing fails' do
      allow_any_instance_of(Protocol).to receive(:update!).and_raise(StandardError, 'boom')

      post :publish, params: { id: repository_protocol.id }, format: :json

      expect(response).to redirect_to(protocols_path)
      expect(flash[:error]).to eq I18n.t('errors.general')
      expect(repository_protocol.reload).to be_in_repository_draft
    end

    it 'sets validation errors in flash on invalid record' do
      allow_any_instance_of(Protocol).to receive(:update!) do |protocol|
        protocol.errors.add(:base, 'invalid protocol')
        raise ActiveRecord::RecordInvalid, protocol
      end

      post :publish, params: { id: repository_protocol.id }, format: :json

      expect(flash[:error]).to eq 'invalid protocol'
    end

    it 'returns 403 for protocol user cannot manage' do
      post :publish, params: { id: foreign_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(foreign_protocol.reload).to be_in_repository_draft
    end
  end

  describe 'POST destroy_draft' do
    it 'renders json message when called from version modal' do
      post :destroy_draft, params: { id: draft_protocol.id, version_modal: true }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['message']).to eq I18n.t('protocols.delete_draft_modal.success')
      expect(Protocol.exists?(draft_protocol.id)).to be false
    end

    it 'redirects to protocols with flash when not from modal' do
      post :destroy_draft, params: { id: draft_protocol.id }, format: :json

      expect(response).to redirect_to(protocols_path)
      expect(flash[:success]).to eq I18n.t('protocols.delete_draft_modal.success')
    end

    it 'returns 422 when draft cannot be destroyed' do
      allow_any_instance_of(Protocol).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'nope')

      post :destroy_draft, params: { id: draft_protocol.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['message']).to eq 'nope'
      expect(Protocol.exists?(draft_protocol.id)).to be true
    end

    it 'returns 422 with general error on unexpected failure' do
      allow_any_instance_of(Protocol).to receive(:destroy!).and_raise(StandardError, 'unexpected')

      post :destroy_draft, params: { id: draft_protocol.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['message']).to eq I18n.t('errors.general')
    end

    it 'returns 403 for an initial draft without parent' do
      post :destroy_draft, params: { id: repository_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(Protocol.exists?(repository_protocol.id)).to be true
    end
  end

  describe 'POST archive / restore' do
    it 'archives the parent protocol when a draft id is passed' do
      post :archive, params: { protocol_ids: [draft_protocol.id] }, format: :json

      expect(response).to have_http_status(:ok)
      expect(published_protocol.reload.archived).to be true
    end

    it 'returns 422 with error message when archiving fails' do
      allow_any_instance_of(Protocol).to receive(:archive).and_return(false)

      post :archive, params: { protocol_ids: [published_protocol.id] }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(published_protocol.reload.archived).to be false
    end

    it 'returns 401 when user cannot archive' do
      post :archive, params: { protocol_ids: [foreign_published_protocol.id] }, format: :json

      expect(response).to have_http_status(:unauthorized)
      expect(foreign_published_protocol.reload.archived).to be false
    end

    it 'returns 401 when user cannot restore' do
      foreign_published_protocol.update_columns(archived: true, archived_by_id: other_user.id, archived_on: Time.zone.now)

      post :restore, params: { protocol_ids: [foreign_published_protocol.id] }, format: :json

      expect(response).to have_http_status(:unauthorized)
      expect(foreign_published_protocol.reload.archived).to be true
    end
  end

  describe 'GET edit' do
    it 'renders show template' do
      get :edit, params: { id: repository_protocol.id }

      expect(response).to render_template(:show)
    end
  end

  describe 'GET show' do
    it 'renders html with inline editing config for manageable protocol' do
      get :show, params: { id: repository_protocol.id }, format: :html

      expect(response).to have_http_status(:ok)
      expect(assigns(:active_tab)).to eq :protocol
      expect(assigns(:inline_editable_title_config)[:path_to_update]).to eq name_protocol_path(repository_protocol)
      expect(assigns(:breadcrumbs_items).last[:label]).to eq repository_protocol.name
    end

    it 'does not set inline editing for a published protocol' do
      get :show, params: { id: published_protocol.id }, format: :html

      expect(assigns(:inline_editable_title_config)).to be_nil
    end

    it 'returns 403 when user cannot read the protocol' do
      get :show, params: { id: foreign_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'update actions failure paths' do
    it 'returns 422 when keywords update fails' do
      allow_any_instance_of(Protocol).to receive(:update_keywords).and_return(false)

      patch :update_keywords, params: { id: repository_protocol.id, keywords: ['kw'] }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'stores keywords on success' do
      patch :update_keywords, params: { id: repository_protocol.id, keywords: %w(alpha beta) }, format: :json

      expect(repository_protocol.reload.protocol_keywords.pluck(:name)).to match_array(%w(alpha beta))
    end

    it 'returns 422 when authors update fails' do
      allow_any_instance_of(Protocol).to receive(:update).and_return(false)

      post :update_authors, params: { id: repository_protocol.id, protocol: { authors: 'x' } }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 when name is blank' do
      post :update_name, params: { id: repository_protocol.id, protocol: { name: '' } }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json).to have_key('name')
    end

    it 'updates the name' do
      post :update_name, params: { id: repository_protocol.id, protocol: { name: 'Renamed' } }, format: :json

      expect(response).to have_http_status(:ok)
      expect(repository_protocol.reload.name).to eq 'Renamed'
    end

    it 'returns 403 on update_name for locked task protocol description' do
      task_protocol = my_module.protocol
      task_protocol.update!(description_locked: true)

      post :update_name, params: { id: task_protocol.id, protocol: { name: 'X' } }, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 on update_description for locked task protocol description' do
      task_protocol = my_module.protocol
      task_protocol.update!(description_locked: true)

      patch :update_description, params: { id: task_protocol.id, protocol: { description: 'X' } }, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 422 when description is too long' do
      patch :update_description,
            params: { id: repository_protocol.id,
                      protocol: { description: 'a' * (Constants::RICH_TEXT_MAX_LENGTH + 1) } },
            format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'updates the description and returns serialized protocol' do
      patch :update_description, params: { id: repository_protocol.id, protocol: { description: 'New desc' } },
                                 format: :json

      expect(response).to have_http_status(:ok)
      expect(repository_protocol.reload.description).to eq 'New desc'
      expect(json.dig('data', 'id')).to eq repository_protocol.id.to_s
    end

    it 'returns 422 when description_locked update fails' do
      allow(Protocol).to receive(:content_locking_enabled?).and_return(true)
      allow_any_instance_of(Protocol).to receive(:update).and_return(false)

      post :update_description_locked, params: { id: repository_protocol.id, protocol: { description_locked: true } },
                                       format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 403 on manage actions for protocol user cannot manage' do
      post :update_authors, params: { id: foreign_protocol.id, protocol: { authors: 'x' } }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(foreign_protocol.reload.authors).not_to eq 'x'
    end
  end

  describe 'POST create' do
    it 'returns 422 when name is missing' do
      post :create, params: { protocol: { name: '' }, team_id: team.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['error']).to be_present
    end

    it 'redirects to the new protocol and grants team access' do
      expect do
        post :create, params: { protocol: { name: 'Brand new', default_public_user_role_id: viewer_role.id },
                                team_id: team.id }, format: :json
      end.to change(TeamAssignment, :count).by(1)

      protocol = Protocol.find_by(name: 'Brand new')
      expect(response).to redirect_to(protocol_path(protocol))
      expect(protocol).to be_in_repository_draft
    end

    it 'returns 403 in archive view mode' do
      expect do
        post :create, params: { protocol: { name: 'Nope' }, team_id: team.id, view_mode: 'archive' }, format: :json
      end.not_to change(Protocol, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST archive_steps' do
    let(:task_protocol) { my_module.protocol }
    let!(:step1) { create :step, protocol: task_protocol, position: 0 }
    let!(:step2) { create :step, protocol: task_protocol, position: 1 }

    it 'archives all active steps and logs activities' do
      expect { post :archive_steps, params: { id: task_protocol.id }, format: :json }
        .to change { Activity.where(type_of: :archive_step).count }.by(2)

      expect(json['status']).to eq 'ok'
      expect(step1.reload.archived).to be true
      expect(step2.reload.archived).to be true
    end

    it 'returns 422 when archiving fails' do
      allow_any_instance_of(Step).to receive(:archive!).and_raise(ActiveRecord::RecordNotDestroyed)

      post :archive_steps, params: { id: task_protocol.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['status']).to eq 'error'
    end

    it 'returns 403 when user cannot manage task protocol' do
      downgrade_my_module_role_to_viewer

      post :archive_steps, params: { id: task_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(step1.reload.archived).to be false
    end
  end

  describe 'POST delete_steps' do
    let!(:step1) { create :step, protocol: repository_protocol, position: 0 }

    it 'removes the steps' do
      post :delete_steps, params: { id: repository_protocol.id }, format: :json

      expect(json['status']).to eq 'ok'
      expect(Step.exists?(step1.id)).to be false
    end

    it 'returns 422 when a step cannot be destroyed' do
      allow_any_instance_of(Step).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

      post :delete_steps, params: { id: repository_protocol.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Step.exists?(step1.id)).to be true
    end

    it 'returns 403 for protocol user cannot manage' do
      create :step, protocol: foreign_protocol, position: 0

      post :delete_steps, params: { id: foreign_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(foreign_protocol.steps.count).to eq 1
    end
  end

  describe 'POST clone' do
    it 'returns success message with new protocol name' do
      post :clone, params: { protocol_ids: repository_protocol.id, team_id: team.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['message']).to include(repository_protocol.name)
    end

    it 'returns 400 when cloning raises' do
      allow_any_instance_of(Protocol).to receive(:deep_clone_repository).and_raise(StandardError, 'clone failed')

      post :clone, params: { protocol_ids: repository_protocol.id, team_id: team.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to eq I18n.t('protocols.index.clone.error_flash', original: repository_protocol.name)
    end

    it 'returns sheet name error message when clone fails on table sheet name' do
      allow_any_instance_of(Protocol).to receive(:deep_clone_repository) do
        table = Table.new
        table.errors.add(:sheet_name, 'taken')
        raise ActiveRecord::RecordInvalid, table
      end

      post :clone, params: { protocol_ids: repository_protocol.id, team_id: team.id }, format: :json

      expect(json['error']).to eq I18n.t('activerecord.errors.models.table.attributes.sheet_name.not_unique_in_context_long')
    end

    it 'returns 403 for protocol user cannot read' do
      foreign_protocol
      expect do
        post :clone, params: { protocol_ids: foreign_protocol.id, team_id: team.id }, format: :json
      end.not_to change(Protocol, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST copy_to_repository' do
    let(:task_protocol) { my_module.protocol }

    it 'returns 400 when copying raises' do
      allow_any_instance_of(Protocol).to receive(:copy_to_repository).and_raise(StandardError, 'copy failed')

      post :copy_to_repository, params: { id: task_protocol.id, protocol: { name: 'copy' } }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to eq I18n.t('my_modules.protocols.copy_to_repository_modal.error_400')
    end

    it 'returns 422 when the new protocol is invalid' do
      expect do
        post :copy_to_repository, params: { id: task_protocol.id, protocol: { name: '' } }, format: :json
      end.not_to change(Protocol, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['error']).to be_present
    end

    it 'returns 403 for protocol outside of a task' do
      post :copy_to_repository, params: { id: repository_protocol.id, protocol: { name: 'x' } }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST save_as_draft' do
    it 'returns url of the new draft' do
      post :save_as_draft, params: { id: published_protocol.id }, format: :json

      draft = Protocol.find_by(parent_id: published_protocol.id, protocol_type: :in_repository_draft)
      expect(json['url']).to eq protocol_path(draft)
      expect(draft.version_number).to eq 2
    end

    it 'returns 422 when draft already exists' do
      draft_protocol

      expect do
        post :save_as_draft, params: { id: published_protocol.id }, format: :json
      end.not_to change(Protocol, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['error']).to be_present
    end

    it 'returns 422 on record invalid during cloning' do
      pending 'bug: sheet_name_error_message treats empty errors[:sheet_name] array as truthy'

      allow_any_instance_of(Protocol).to receive(:save_as_draft) do |protocol|
        raise ActiveRecord::RecordInvalid, protocol
      end

      post :save_as_draft, params: { id: published_protocol.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['error']).to eq I18n.t('my_modules.protocols.copy_to_repository_modal.error_400')
    end

    it 'returns 422 with general error on unexpected failure' do
      allow_any_instance_of(Protocol).to receive(:save_as_draft).and_raise(StandardError)

      post :save_as_draft, params: { id: published_protocol.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['error']).to eq I18n.t('errors.general')
    end

    it 'returns 403 for a draft protocol' do
      post :save_as_draft, params: { id: repository_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST unlink' do
    it 'sets success flash and returns empty json' do
      post :unlink, params: { id: linked_protocol.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(flash[:success]).to eq I18n.t('my_modules.protocols.unlink_flash')
      expect(linked_protocol.reload).to be_unlinked
    end

    it 'returns 400 when unlink raises' do
      allow_any_instance_of(Protocol).to receive(:unlink).and_raise(StandardError)

      post :unlink, params: { id: linked_protocol.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to eq I18n.t('my_modules.protocols.unlink_error')
    end

    it 'returns 403 when protocol is not linked' do
      post :unlink, params: { id: my_module.protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST revert' do
    it 'reverts and sets flash' do
      post :revert, params: { id: linked_protocol.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(flash[:success]).to eq I18n.t('my_modules.protocols.revert_flash')
    end

    it 'returns 400 when loading fails' do
      allow_any_instance_of(Protocol).to receive(:load_from_repository).and_raise(StandardError)

      post :revert, params: { id: linked_protocol.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json['message']).to eq I18n.t('my_modules.protocols.revert_error')
    end

    it 'returns 400 when protocol cannot be destroyed' do
      allow_any_instance_of(Protocol).to receive(:can_destroy?).and_return(false)

      post :revert, params: { id: linked_protocol.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json['message']).to eq I18n.t('my_modules.protocols.revert_error_locked')
    end

    it 'returns 403 when protocol has locked steps' do
      create :step, protocol: linked_protocol, locked: true

      post :revert, params: { id: linked_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 when protocol has no parent' do
      post :revert, params: { id: my_module.protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST update_from_parent' do
    let(:published_version) do
      create :protocol, :in_repository_published_version,
             team: team, added_by: user, parent: published_protocol, version_number: 2
    end

    it 'loads latest version when linked to a published version' do
      linked = create :protocol, :linked_to_repository, my_module: my_module, parent: published_version,
                                                        team: team, added_by: user

      post :update_from_parent, params: { id: linked.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(flash[:success]).to eq I18n.t('my_modules.protocols.update_from_parent_flash')
      expect(linked.reload.parent).to eq published_version
    end

    it 'returns 400 when loading fails' do
      allow_any_instance_of(Protocol).to receive(:load_from_repository).and_raise(StandardError)

      post :update_from_parent, params: { id: linked_protocol.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json['message']).to eq I18n.t('my_modules.protocols.update_from_parent_error')
    end

    it 'returns 400 when protocol is locked' do
      allow_any_instance_of(Protocol).to receive(:can_destroy?).and_return(false)

      post :update_from_parent, params: { id: linked_protocol.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json['message']).to eq I18n.t('my_modules.protocols.update_from_parent_error_locked')
    end
  end

  describe 'POST load_from_repository' do
    let(:task_protocol) { my_module.protocol }

    it 'logs merge activity in merge mode' do
      post :load_from_repository,
           params: { id: task_protocol.id, source_id: published_protocol.id, load_mode: 'merge' }, format: :json

      expect(response).to have_http_status(:ok)
      expect(Activity.last.type_of).to eq 'load_protocol_to_task_from_repository_merge'
    end

    it 'returns 400 when loading fails' do
      allow_any_instance_of(Protocol).to receive(:load_from_repository).and_raise(StandardError, 'load failed')

      post :load_from_repository, params: { id: task_protocol.id, source_id: published_protocol.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json['message']).to eq I18n.t('my_modules.protocols.load_from_repository_error')
    end

    it 'returns 400 when protocol is locked' do
      allow_any_instance_of(Protocol).to receive(:can_destroy?).and_return(false)

      post :load_from_repository, params: { id: task_protocol.id, source_id: published_protocol.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json['message']).to eq I18n.t('my_modules.protocols.load_from_repository_error_locked')
    end

    it 'returns 403 when source is not readable' do
      post :load_from_repository,
           params: { id: task_protocol.id, source_id: foreign_published_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET protocolsio_index' do
    it 'returns 403 when protocols.io is disabled' do
      allow(Protocol).to receive(:protocols_io_enabled?).and_return(false)

      get :protocolsio_index, params: { team_id: team.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'renders modal body when enabled' do
      allow(Protocol).to receive(:protocols_io_enabled?).and_return(true)

      get :protocolsio_index, params: { team_id: team.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json).to have_key('html')
    end
  end

  describe 'POST import' do
    let(:v2_json) do
      {
        name: 'Imported v2',
        authors: 'Someone',
        elnVersion: '1.2',
        description: '<p>desc</p>',
        steps: {
          '0' => {
            name: 'Step one',
            stepElements: {
              '0' => { type: 'StepText', stepText: { contents: '<p>hello</p>', name: 'txt' } },
              '1' => { type: 'Checklist', checklist: { name: 'CL', items: { '0' => { text: 'item 1' } } } }
            }
          }
        }
      }
    end

    it 'imports a v1.2 protocol with steps using ProtocolsImporterV2' do
      expect do
        post :import, params: { team_id: team.id, protocol: v2_json }, format: :json
      end.to change(Protocol, :count).by(1)

      protocol = Protocol.order(:id).last
      expect(json['status']).to eq 'ok'
      expect(protocol.name).to eq 'Imported v2'
      expect(protocol.steps.first.checklists.first.checklist_items.pluck(:text)).to eq ['item 1']
    end

    it 'returns 400 when the importer is not set for unknown version' do
      expect do
        post :import, params: { team_id: team.id, protocol: v2_json.merge(elnVersion: '9.9') }, format: :json
      end.not_to change(Protocol, :count)

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 403 when user cannot create protocols' do
      allow(controller).to receive(:can_create_protocols_in_repository?).and_return(false)

      post :import, params: { team_id: team.id, protocol: v2_json }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET export' do
    let!(:step) { create :step, protocol: repository_protocol, position: 0 }
    let!(:step_asset) { create :step_asset, step: step }
    let!(:step_text) { create :step_text, step: step, text: '<p>text</p>' }

    it 'exports a single repository protocol as eln zip and logs activity' do
      expect do
        get :export, params: { protocol_ids: [repository_protocol.id] }
      end.to change { Activity.where(type_of: :export_protocol_in_repository).count }.by(1)

      expect(response.headers['Content-Disposition']).to include(".eln")
      entries = []
      Zip::InputStream.open(StringIO.new(response.body)) do |io|
        while (entry = io.get_next_entry)
          entries << entry.name
        end
      end
      expect(entries).to include('scinote.xml', 'scinote.xsd', 'eln.xsd')
      expect(entries.any? { |e| e.end_with?('/eln.xml') }).to be true
      expect(entries.any? { |e| e.include?('/steps/') && e.end_with?('.jpg') }).to be true
    end

    it 'names the archive protocols.eln when exporting multiple protocols' do
      get :export, params: { protocol_ids: [repository_protocol.id, published_protocol.id] }

      expect(response.headers['Content-Disposition']).to include('protocols.eln')
    end

    it 'exports a task protocol with its results' do
      result = create :result, my_module: my_module, user: user
      create :result_text, result: result
      task_protocol = my_module.protocol

      get :export, params: { protocol_ids: [task_protocol.id], my_module_id: my_module.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_present
    end

    it 'returns 403 when protocol is not readable' do
      get :export, params: { protocol_ids: [foreign_protocol.id] }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET load_from_repository_datatable' do
    it 'returns datatable json' do
      published_protocol

      post :load_from_repository_datatable,
           params: { id: my_module.protocol.id, draw: 1, start: 0, length: 10,
                     order: { '0' => { column: '0', dir: 'asc' } },
                     columns: { '0' => { data: '0', orderable: 'true' } } },
           format: :json

      expect(response).to have_http_status(:ok)
      expect(json['recordsTotal']).to eq 1
      expect(json['data'].first['DT_RowId']).to eq published_protocol.id
    end

    it 'returns 403 when user cannot read task protocol' do
      downgrade_my_module_role_to_viewer
      UserAssignment.where(user: user, assignable: my_module).destroy_all

      post :load_from_repository_datatable, params: { id: my_module.protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET list_published_protocol_templates' do
    it 'filters by query' do
      matching = create :protocol, :in_repository_published_original, team: team, added_by: user, name: 'Alpha PCR'
      create :protocol, :in_repository_published_original, team: team, added_by: user, name: 'Beta'

      get :list_published_protocol_templates, params: { id: my_module.protocol.id, query: 'Alpha' }, format: :json

      expect(json['data']).to eq [[matching.id, 'Alpha PCR']]
    end
  end

  describe 'version comment' do
    it 'returns the version comment' do
      repository_protocol.update!(version_comment: 'notes')

      get :version_comment, params: { id: repository_protocol.id }, format: :json

      expect(json['version_comment']).to eq 'notes'
    end

    it 'updates the version comment and logs activity' do
      expect do
        put :update_version_comment, params: { id: repository_protocol.id, protocol: { version_comment: 'new' } },
                                       format: :json
      end.to change { Activity.where(type_of: :protocol_template_revision_notes_updated).count }.by(1)

      expect(json['version_comment']).to eq 'new'
    end

    it 'returns 422 when the version comment is invalid' do
      allow_any_instance_of(Protocol).to receive(:update).and_return(false)

      put :update_version_comment, params: { id: repository_protocol.id, protocol: { version_comment: 'x' } },
                                     format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json).to have_key('errors')
    end

    it 'returns 403 for published protocol' do
      get :version_comment, params: { id: published_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET permissions' do
    it 'returns permission flags' do
      pending 'bug: stale? is given a CollectionProxy (team.user_assignments) which has no updated_at -> 500'
      get :permissions, params: { id: published_protocol.id }, format: :json

      expect(json).to eq('copyable' => true, 'archivable' => true, 'restorable' => false, 'readable' => true)
    end

    it 'returns 403 for foreign protocol' do
      get :permissions, params: { id: foreign_protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET actions_toolbar' do
    it 'returns toolbar actions for given items' do
      post :actions_toolbar, params: { items: [{ id: published_protocol.id }].to_json }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['actions']).to be_an(Array)
      expect(json['actions'].map { |a| a['name'] }).to include('archive')
    end
  end

  describe 'GET user_roles' do
    it 'returns roles collection' do
      get :user_roles, format: :json

      expect(json['data']).to be_an(Array)
      expect(json['data'].flatten).to include(owner_role.name)
    end
  end
end
