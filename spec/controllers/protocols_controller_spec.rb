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
      expect(JSON.parse(response.body)['data']).to be_an(Array)
    end

    it 'returns a successful response for non-owners' do
      allow(controller).to receive(:can_manage_team?).and_return(false)

      action
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['data']).to be_an(Array)
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

    it 'serializes published versions for published protocols' do
      get :versions_modal, params: { id: published_protocol.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['versions']).to be_an(Array)
      expect(JSON.parse(response.body)['versions']).not_to be_empty
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
      expect(JSON.parse(response.body)['data']).to be_an(Array)
      expect(JSON.parse(response.body)['data'].length).to eq(1)
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
      expect(JSON.parse(response.body)['versions']).to be_an(Array)
      expect(JSON.parse(response.body)['versions'].length).to eq(1)
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

    it 'returns url when publishing from show view' do
      post :publish, params: { id: repository_protocol.id, view: 'show' }, format: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('url')
    end

    it 'sets flash error when record is invalid' do
      allow_any_instance_of(Protocol).to receive(:update!) do |protocol|
        protocol.errors.add(:base, 'invalid')
        raise ActiveRecord::RecordInvalid, protocol
      end

      action

      expect(flash[:error]).to include('invalid')
      expect(response).to redirect_to(protocols_path)
    end

    it 'sets flash error on unexpected exception' do
      allow_any_instance_of(Protocol).to receive(:update!).and_raise(StandardError, 'boom')

      action

      expect(flash[:error]).to eq(I18n.t('errors.general'))
      expect(response).to redirect_to(protocols_path)
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

    it 'returns a json message when called from versions modal' do
      post :destroy_draft, params: { id: draft_protocol.id, version_modal: true }, format: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('message')
    end

    it 'returns unprocessable_entity when draft cannot be destroyed' do
      allow_any_instance_of(Protocol)
        .to receive(:destroy!)
        .and_raise(ActiveRecord::RecordNotDestroyed.new('cannot destroy'))

      post :destroy_draft, params: { id: draft_protocol.id, version_modal: true }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key('message')
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
      expect(JSON.parse(response.body)['data']).to include('id' => repository_protocol.id.to_s)
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
      expect(copied_protocol.name).to eq('test')
      expect(copied_protocol.description).to eq(protocol_in_task.description)
      expect(copied_protocol.protocol_type).to eq('in_repository_draft')
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
          elnVersion: '1.0'
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
      { id: repository_protocol.id, keywords: %w(keyword-1 keyword-2) }
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
                                     :load_protocol_to_task_from_repository)))
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

  describe 'GET permissions' do
    let(:params) { { id: repository_protocol.id } }
    let(:action) { get :permissions, params: params, format: :json }

    before do
      allow(controller).to receive(:stale?).and_return(true)
      allow(controller).to receive(:can_clone_protocol_in_repository?).and_return(true)
      allow(controller).to receive(:can_archive_protocol_in_repository?).and_return(true)
      allow(controller).to receive(:can_restore_protocol_in_repository?).and_return(true)
      allow(controller).to receive(:can_read_protocol_in_repository?).and_return(true)
    end

    it 'returns permission flags' do
      action

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to include(
        'copyable' => true,
        'archivable' => true,
        'restorable' => true,
        'readable' => true
      )
    end
  end

  describe 'GET actions_toolbar' do
    let(:params) { { items: [{ id: repository_protocol.id }].to_json } }
    let(:action) { get :actions_toolbar, params: params, format: :json }

    it 'returns actions from toolbar service' do
      service = instance_double(Toolbars::ProtocolsService, actions: [{ name: 'test' }])
      allow(Toolbars::ProtocolsService).to receive(:new).and_return(service)

      action
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to eq('actions' => [{ 'name' => 'test' }])
    end
  end

  describe 'GET user_roles' do
    let(:action) { get :user_roles, format: :json }

    it 'returns user roles collection' do
      action
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('data')
    end
  end

  describe 'GET version_comment' do
    let(:params) { { id: repository_protocol.id } }
    let(:action) { get :version_comment, params: params, format: :json }

    before do
      allow(controller).to receive(:can_publish_protocol_in_repository?).and_return(true)
    end

    it 'returns version_comment' do
      action
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('version_comment')
    end
  end

  describe 'POST update_version_comment' do
    let(:params) do
      {
        id: repository_protocol.id,
        protocol: {
          version_comment: 'revision notes'
        }
      }
    end

    let(:action) { post :update_version_comment, params: params, format: :json }

    before do
      allow(controller).to receive(:can_publish_protocol_in_repository?).and_return(true)
    end

    it 'updates version_comment' do
      action
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['version_comment']).to eq('revision notes')
    end

    it 'returns validation errors when update fails' do
      allow_any_instance_of(Protocol).to receive(:update).and_return(false)

      action
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key('errors')
    end
  end

  describe 'GET versions_modal' do
    let(:published_version) do
      create :protocol, :in_repository_published_version,
             team: team,
             added_by: user,
             parent: published_protocol,
             version_number: 2
    end

    it 'returns forbidden for non-original published versions' do
      get :versions_modal, params: { id: published_version.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET linked_children with version' do
    let(:published_version) do
      create :protocol, :in_repository_published_version,
             team: team,
             added_by: user,
             parent: published_protocol,
             version_number: 2
    end

    let(:linked_protocol) do
      create :protocol, :linked_to_repository,
             name: ' test protocol',
             my_module: my_module,
             parent: published_version,
             team: team,
             added_by: user
    end

    it 'returns linked children for a specific version' do
      linked_protocol

      get :linked_children, params: { id: published_protocol.id, version: 2 }, format: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['data'].length).to eq(1)
    end
  end

  describe 'POST copy_to_repository' do
    let(:protocol_in_task) do
      create :protocol, name: 'test protocol', my_module: my_module
    end

    let(:params) { { id: protocol_in_task.id, team_id: team.id, protocol: { name: 'test' } } }

    it 'returns bad_request when copy fails in transaction' do
      allow_any_instance_of(Protocol)
        .to receive(:copy_to_repository)
        .and_raise(StandardError, 'copy failed')

      post :copy_to_repository, params: params, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to have_key('message')
    end
  end

  describe 'POST archive' do
    let(:protocol_to_archive) do
      create :protocol, :in_repository_published_original, team: team, added_by: user
    end

    it 'returns unprocessable_entity when archiving fails' do
      protocol_to_archive.errors.add(:base, 'archive failed')
      allow_any_instance_of(Protocol).to receive(:archive).and_return(false)

      post :archive, params: { protocol_ids: [protocol_to_archive.id] }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key('message')
    end
  end

  describe 'GET load_from_repository_datatable' do
    it 'returns datatable JSON' do
      datatable = instance_double(LoadFromRepositoryProtocolsDatatable, as_json: { draw: 1, data: [] })
      allow(LoadFromRepositoryProtocolsDatatable).to receive(:new).and_return(datatable)

      get :load_from_repository_datatable, params: { id: my_module.protocol.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(JSON.parse(response.body)).to include('draw' => 1, 'data' => [])
    end
  end

  describe 'GET show (html)' do
    it 'sets the active tab' do
      get :show, params: { id: repository_protocol.id }, format: :html

      expect(response).to have_http_status(:success)
      expect(assigns(:active_tab)).to eq(:protocol)
    end
  end

  describe 'GET print' do
    it 'renders print layout' do
      get :print, params: { id: repository_protocol.id }, format: :html

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET index (html)' do
    it 'renders index template' do
      get :index, params: { team_id: team.id }, format: :html

      expect(response).to have_http_status(:success)
      expect(response).to render_template('index')
    end
  end
end
