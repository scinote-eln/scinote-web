# frozen_string_literal: true

require 'rails_helper'

describe MyModuleRepositorySnapshotsController, type: :controller do
  login_user
  render_views
  include_context 'reference_project_structure'

  let!(:repository) { create :repository, created_by: user, team: team }
  let!(:repository_row) { create :repository_row, created_by: user, repository: repository }
  let!(:snapshot) do
    create :repository_snapshot, original_repository: repository, my_module: my_module, status: :ready
  end

  def json
    JSON.parse(response.body)
  end

  def make_viewer
    UserAssignment.where(user: user, assignable: [project, experiment, my_module]).update_all(user_role_id: viewer_role.id)
  end

  describe 'POST create' do
    it 'creates a provisioning snapshot, enqueues provisioning and logs activity' do
      expect(RepositorySnapshotProvisioningJob).to receive(:perform_later)
      expect do
        post :create, params: { my_module_id: my_module.id, repository_id: repository.id }, format: :json
      end.to change { my_module.repository_snapshots.count }.by(1)
                                                              .and(change { Activity.where(type_of: :repository_snapshot_created).count }.by(1))
      expect(response).to have_http_status(:ok)
      expect(my_module.repository_snapshots.order(:id).last.status).to eq 'provisioning'
    end

    it 'is forbidden for a viewer' do
      make_viewer
      expect do
        post :create, params: { my_module_id: my_module.id, repository_id: repository.id }, format: :json
      end.not_to(change { RepositorySnapshot.count })
      expect(response).to have_http_status(:forbidden)
    end

    it 'raises ArgumentError for an unknown repository' do
      # bug: app/controllers/my_module_repository_snapshots_controller.rb:158 checks permission on nil
      # right after render_404, so the request raises instead of answering 404
      expect do
        post :create, params: { my_module_id: my_module.id, repository_id: -1 }, format: :json
      end.to raise_error(ArgumentError)
    end
  end

  describe 'GET status' do
    it 'returns the snapshot status' do
      get :status, params: { my_module_id: my_module.id, id: snapshot.id }, format: :json
      expect(json).to eq('status' => 'ready')
    end

    it 'returns 404 for a snapshot of another module' do
      other = create :my_module, experiment: experiment, created_by: user
      get :status, params: { my_module_id: other.id, id: snapshot.id }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden without module access' do
      UserAssignment.where(user: user, assignable: [project, experiment, my_module]).destroy_all
      get :status, params: { my_module_id: my_module.id, id: snapshot.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the snapshot and logs activity' do
      expect do
        delete :destroy, params: { my_module_id: my_module.id, id: snapshot.id }, format: :json
      end.to change { RepositorySnapshot.count }.by(-1)
                                                .and(change { Activity.where(type_of: :repository_snapshot_deleted).count }.by(1))
      expect(response).to have_http_status(:ok)
    end

    it 'is forbidden for a viewer' do
      make_viewer
      expect do
        delete :destroy, params: { my_module_id: my_module.id, id: snapshot.id }, format: :json
      end.not_to(change { RepositorySnapshot.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET snapshot_list' do
    it 'lists snapshots of the repository and reports live version availability' do
      get :snapshot_list, params: { my_module_id: my_module.id, repository_id: repository.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(json['data'].map { |s| s['id'].to_i }).to eq [snapshot.id]
      expect(json['meta']['has_live_version']).to be true
    end

    it 'accepts a snapshot id as repository id' do
      get :snapshot_list, params: { my_module_id: my_module.id, repository_id: snapshot.id }, format: :json
      expect(json['data'].size).to eq 1
    end
  end

  describe 'POST select' do
    it 'selects the given snapshot' do
      post :select, params: { my_module_id: my_module.id, repository_snapshot_id: snapshot.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(snapshot.reload.selected).to be true
    end

    it 'deselects snapshots when a repository id is given' do
      snapshot.update!(selected: true)
      post :select, params: { my_module_id: my_module.id, repository_id: repository.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(snapshot.reload.selected).to be_nil
    end

    it 'raises ArgumentError for an unknown snapshot (same load_repository bug as create)' do
      expect do
        post :select, params: { my_module_id: my_module.id, repository_snapshot_id: snapshot.id + 1000 }, format: :json
      end.to raise_error(ArgumentError)
    end

    it 'is forbidden for a viewer' do
      make_viewer
      post :select, params: { my_module_id: my_module.id, repository_snapshot_id: snapshot.id }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(snapshot.reload.selected).not_to be true
    end
  end

  describe 'POST export_repository_snapshot' do
    it 'enqueues an export and logs activity' do
      expect(RepositoryZipExportJob).to receive(:perform_later)
      expect do
        post :export_repository_snapshot, params: { my_module_id: my_module.id, id: snapshot.id, header_ids: [-3] },
                                          format: :json
      end.to change { Activity.where(type_of: :export_inventory_snapshot_items_assigned_to_task).count }.by(1)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 without header ids' do
      post :export_repository_snapshot, params: { my_module_id: my_module.id, id: snapshot.id }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'actions whose partials are missing' do
    # bug: app/views/my_modules/repositories/ only holds consume_modal.json.jbuilder, so the partials
    # full_view_version, full_view_snapshot_table and full_view_sidebar do not exist and these raise
    it 'show raises MissingTemplate' do
      expect { get :show, params: { my_module_id: my_module.id, id: snapshot.id }, format: :json }
        .to raise_error(ActionView::MissingTemplate)
    end

    it 'full_view_table raises MissingTemplate' do
      expect { get :full_view_table, params: { my_module_id: my_module.id, id: snapshot.id }, format: :json }
        .to raise_error(ActionView::MissingTemplate)
    end

    it 'full_view_sidebar raises MissingTemplate' do
      expect do
        get :full_view_sidebar, params: { my_module_id: my_module.id, repository_id: repository.id }, format: :json
      end.to raise_error(ActionView::MissingTemplate)
    end
  end

  it 'returns 404 for an unknown module' do
    get :status, params: { my_module_id: -1, id: snapshot.id }, format: :json
    expect(response).to have_http_status(:not_found)
  end
end
