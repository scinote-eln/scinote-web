# frozen_string_literal: true

require 'rails_helper'

describe MyModuleShareableLinksController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  before do
    team.update!(shareable_links_enabled: true)
  end

  let(:json) { JSON.parse(response.body) }

  describe 'authenticated link management' do
    describe 'GET show' do
      let!(:shareable_link) { create :shareable_link, shareable: my_module, created_by: user, description: 'Shared!' }

      it 'returns shareable link url and description' do
        get :show, params: { my_module_id: my_module.id }, format: :json

        expect(response).to have_http_status(:success)
        expect(json['data']['attributes']).to include('description' => 'Shared!')
        expect(json['data']['attributes']['shareable_url']).to end_with("/shared/#{shareable_link.uuid}/protocol")
      end

      it 'returns forbidden without read permission' do
        allow(controller).to receive(:can_read_my_module?).and_return(false)

        get :show, params: { my_module_id: my_module.id }, format: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns not found for unknown task' do
        get :show, params: { my_module_id: -1 }, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'POST create' do
      let(:action) { post :create, params: { my_module_id: my_module.id, description: 'Look at this' }, format: :json }

      it 'creates a shareable link and logs activity' do
        expect { action }.to change(ShareableLink, :count).by(1)
          .and(change { Activity.where(type_of: :task_link_sharing_enabled).count }.by(1))

        link = my_module.reload.shareable_link
        expect(link).to have_attributes(description: 'Look at this', created_by: user, team: team)
        expect(json['data']['attributes']['description']).to eq('Look at this')
      end

      it 'returns forbidden when sharing is disabled for the team' do
        team.update!(shareable_links_enabled: false)

        expect { action }.not_to change(ShareableLink, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns forbidden without share permission' do
        allow(controller).to receive(:can_share_my_module?).and_return(false)

        expect { action }.not_to change(ShareableLink, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PATCH update' do
      let!(:shareable_link) { create :shareable_link, shareable: my_module, created_by: user }

      it 'updates description and logs activity' do
        expect do
          patch :update, params: { my_module_id: my_module.id, description: 'New text' }, format: :json
        end.to change { Activity.where(type_of: :shared_task_message_edited).count }.by(1)

        expect(shareable_link.reload).to have_attributes(description: 'New text', last_modified_by: user)
        expect(json['data']['attributes']['description']).to eq('New text')
      end

      it 'returns forbidden without share permission' do
        allow(controller).to receive(:can_share_my_module?).and_return(false)

        patch :update, params: { my_module_id: my_module.id, description: 'New text' }, format: :json

        expect(response).to have_http_status(:forbidden)
        expect(shareable_link.reload.description).not_to eq('New text')
      end
    end

    describe 'DELETE destroy' do
      let!(:shareable_link) { create :shareable_link, shareable: my_module, created_by: user }

      it 'removes the link and logs activity' do
        expect do
          delete :destroy, params: { my_module_id: my_module.id }, format: :json
        end.to change(ShareableLink, :count).by(-1)
          .and(change { Activity.where(type_of: :task_link_sharing_disabled).count }.by(1))

        expect(json).to eq({})
      end

      it 'returns forbidden without share permission' do
        allow(controller).to receive(:can_share_my_module?).and_return(false)

        expect do
          delete :destroy, params: { my_module_id: my_module.id }, format: :json
        end.not_to change(ShareableLink, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'public shared views' do
    let!(:shareable_link) { create :shareable_link, shareable: my_module, created_by: user }
    let(:uuid) { shareable_link.uuid }

    before { sign_out :user }

    describe 'GET protocol_show' do
      it 'renders the shared protocol page without authentication' do
        get :protocol_show, params: { uuid: uuid }

        expect(response).to have_http_status(:success)
        expect(response).to render_template('shareable_links/my_module_protocol_show')
        expect(assigns(:my_module)).to eq(my_module)
        expect(assigns(:disable_smart_annotation_links)).to be(true)
      end

      it 'returns not found for unknown uuid' do
        get :protocol_show, params: { uuid: 'unknown' }

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET results_show' do
      let!(:result_b) { create :result, my_module: my_module, user: user, name: 'B result' }
      let!(:result_a) { create :result, my_module: my_module, user: user, name: 'A result' }
      let!(:archived_result) { create :result, :archived, my_module: my_module, user: user, name: 'C archived' }

      it 'lists active results newest first by default' do
        get :results_show, params: { uuid: uuid }

        expect(response).to have_http_status(:success)
        expect(response).to render_template('shareable_links/my_module_results_show')
        expect(assigns(:results_order)).to eq('new')
        expect(assigns(:results).to_a).to eq([result_a, result_b])
      end

      {
        'atoz' => %w(A B),
        'ztoa' => %w(B A),
        'old' => %w(B A),
        'old_updated' => %w(B A),
        'new_updated' => %w(A B)
      }.each do |order, expected|
        it "orders results by #{order}" do
          get :results_show, params: { uuid: uuid, order: order }

          expect(assigns(:results).map { |r| r.name[0] }).to eq(expected)
        end
      end

      it 'finds the page of a requested result' do
        get :results_show, params: { uuid: uuid, result_id: result_b.id }

        expect(assigns(:results).current_page).to eq(1)
        expect(assigns(:results)).to include(result_b)
      end

      it 'collects gallery asset ids of results' do
        result_asset = create :result_asset, result: result_a

        get :results_show, params: { uuid: uuid }

        expect(assigns(:gallery)).to eq([result_asset.asset.id])
      end
    end

    describe 'GET repositories_show' do
      it 'lists assigned live repositories and selected snapshots' do
        live_repository = create :repository, team: team, created_by: user
        live_row = create :repository_row, repository: live_repository, created_by: user
        create :mm_repository_row, repository_row: live_row, my_module: my_module, assigned_by: user

        snapshotted_repository = create :repository, team: team, created_by: user
        snapshot = create :repository_snapshot, original_repository: snapshotted_repository,
                                                my_module: my_module, selected: true
        create :repository_row, repository: snapshot, created_by: user

        get :repositories_show, params: { uuid: uuid }

        expect(response).to have_http_status(:success)
        expect(response).to render_template('shareable_links/my_module_repositories_show')
        expect(assigns(:assigned_repositories)).to contain_exactly(
          { id: live_repository.id, name: live_repository.name, assigned_rows_count: 1, is_snapshot: false },
          { id: snapshot.id, name: snapshot.name, assigned_rows_count: 1, is_snapshot: true }
        )
      end

      it 'returns empty list when nothing is assigned' do
        get :repositories_show, params: { uuid: uuid }

        expect(assigns(:assigned_repositories)).to eq([])
      end
    end

    describe 'repository endpoints' do
      let!(:repository) { create :repository, team: team, created_by: user }
      let!(:column) { create :repository_column, repository: repository, created_by: user, name: 'Shared column' }
      let!(:row) { create :repository_row, repository: repository, created_by: user, name: 'Shared row' }

      before { create :mm_repository_row, repository_row: row, my_module: my_module, assigned_by: user }

      it 'returns columns of the assigned repository' do
        get :repository_columns, params: { uuid: uuid, id: repository.id }, format: :json

        expect(response).to have_http_status(:success)
        expect(json['data'].map { |c| c['attributes']['name'] }).to include('Shared column')
      end

      it 'returns assigned rows of the repository' do
        get :repository_index_ag, params: { uuid: uuid, id: repository.id, per_page: 10 }, format: :json

        expect(response).to have_http_status(:success)
        expect(json['data'].size).to eq(1)
        expect(json['meta']).to include('total_count' => 1, 'total_pages' => 1)
      end

      it 'returns not found for a repository not assigned to the task' do
        other_repository = create :repository, team: team, created_by: user

        get :repository_columns, params: { uuid: uuid, id: other_repository.id }, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET download_asset' do
      it 'redirects to the file url of a result asset' do
        result = create :result, my_module: my_module, user: user
        result_asset = create :result_asset, result: result
        file_double = double('file', url: 'https://files.example.com/test.jpg')
        allow_any_instance_of(Asset).to receive(:file).and_return(file_double)

        get :download_asset, params: { uuid: uuid, id: result_asset.asset.id }

        expect(response).to redirect_to('https://files.example.com/test.jpg')
        expect(file_double).to have_received(:url).with(hash_including(disposition: 'attachment'))
      end

      it 'returns not found for asset not belonging to the task' do
        asset = create :asset, team: team

        get :download_asset, params: { uuid: uuid, id: asset.id }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
