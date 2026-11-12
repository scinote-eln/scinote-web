# frozen_string_literal: true

require 'rails_helper'

describe StorageLocationsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:viewer_role) { create :viewer_role }
  let(:location) { create_location(name: 'Freezer') }
  let(:container) do
    create_location(name: 'Box', container: true, parent: location,
                    metadata: { display_type: 'grid', dimensions: [2, 2] })
  end

  def create_location(name:, container: false, parent: nil, metadata: {}, location_team: team)
    StorageLocation.create!(name: name, container: container, parent: parent, metadata: metadata,
                            team: location_team, created_by: user)
  end

  def make_team_viewer!
    team.user_assignments.find_by(user: user).update!(user_role: viewer_role)
  end

  before do
    allow(StorageLocation).to receive(:storage_locations_enabled?).and_return(true)
  end

  describe 'when storage locations are disabled' do
    it 'renders 403' do
      allow(StorageLocation).to receive(:storage_locations_enabled?).and_return(false)
      get :tree, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET index' do
    it 'lists root storage locations of the current team' do
      location
      create_location(name: 'Other team location', location_team: create(:team))

      get :index, format: :json

      expect(response).to have_http_status(:success)
      names = JSON.parse(response.body)['data'].map { |d| d['attributes']['name'] }
      expect(names).to eq ['Freezer']
    end

    it 'lists children of the given parent location' do
      container

      get :index, params: { parent_id: location.id }, format: :json

      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body['data'].map { |d| d['attributes']['name'] }).to eq ['Box']
      expect(body['meta']).to include('total_count' => 1)
    end

    it 'renders 403 when parent location is not readable' do
      foreign = create_location(name: 'Foreign', location_team: create(:team))

      get :index, params: { parent_id: foreign.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET show' do
    it 'redirects to the index for non container locations' do
      get :show, params: { id: location.id }

      expect(response).to redirect_to(storage_locations_path(parent_id: location.id))
    end

    it 'renders the container page with breadcrumbs' do
      get :show, params: { id: container.id }

      expect(response).to have_http_status(:success)
      expect(assigns(:breadcrumbs_items).map { |i| i[:label] }).to include('Freezer', 'Box')
      expect(assigns(:inline_editable_title_config)[:item_id]).to eq container.id
    end

    it 'renders 404 for a location of another team' do
      foreign = create_location(name: 'Foreign', location_team: create(:team))

      get :show, params: { id: foreign.id }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST create' do
    let(:params) { { name: 'New location', description: 'Shelf' } }

    it 'creates a storage location and logs activity' do
      expect { post :create, params: params, format: :json }
        .to change(StorageLocation, :count).by(1)
        .and change { Activity.where(type_of: :storage_location_created).count }.by(1)

      expect(response).to have_http_status(:success)
      created = StorageLocation.last
      expect(created.team).to eq team
      expect(created.created_by).to eq user
      expect(JSON.parse(response.body)['data']['attributes']['name']).to eq 'New location'
    end

    it 'creates a container in a parent location' do
      post :create, params: { name: 'Rack', container: true, parent_id: location.id,
                              metadata: { display_type: 'grid', dimensions: [3, 4] } }, format: :json

      expect(response).to have_http_status(:success)
      created = StorageLocation.find_by(name: 'Rack')
      expect(created.parent).to eq location
      expect(created.grid_size).to eq %w(3 4)
      expect(Activity.where(type_of: :container_storage_location_created).count).to eq 1
    end

    it 'returns errors for invalid data' do
      post :create, params: { name: 'a' * 300 }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to be_present
    end

    it 'renders 403 without create permission' do
      make_team_viewer!

      expect { post :create, params: params, format: :json }.not_to change(StorageLocation, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT update' do
    it 'updates name and description and logs activity' do
      put :update, params: { id: location.id, name: 'Renamed', description: 'New desc', file_name: 'x' },
                   format: :json

      expect(response).to have_http_status(:success)
      expect(location.reload.name).to eq 'Renamed'
      expect(location.description).to eq 'New desc'
      expect(Activity.where(type_of: :storage_location_edited, subject: location).count).to eq 1
    end

    it 'returns errors for invalid data' do
      put :update, params: { id: location.id, name: 'a' * 300, file_name: 'x' }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(location.reload.name).to eq 'Freezer'
    end

    it 'renders 403 without manage permission' do
      make_team_viewer!

      put :update, params: { id: location.id, name: 'Renamed' }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(location.reload.name).to eq 'Freezer'
    end
  end

  describe 'DELETE destroy' do
    it 'discards the location with children' do
      container

      delete :destroy, params: { id: location.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(StorageLocation.with_discarded.find(location.id)).to be_discarded
      expect(StorageLocation.with_discarded.find(container.id)).to be_discarded
      expect(Activity.where(type_of: :storage_location_deleted).count).to eq 1
    end

    it 'renders 403 without manage permission' do
      make_team_viewer!

      delete :destroy, params: { id: location.id }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(location.reload).not_to be_discarded
    end
  end

  describe 'POST duplicate' do
    it 'duplicates the location with its children' do
      container

      expect { post :duplicate, params: { id: location.id }, format: :json }
        .to change(StorageLocation, :count).by(2)

      expect(response).to have_http_status(:success)
      copy = StorageLocation.find(JSON.parse(response.body)['data']['id'])
      expect(copy.name).to eq 'Clone 1 - Freezer'
      expect(copy.storage_locations.pluck(:name)).to eq ['Box']
      expect(Activity.where(type_of: :storage_location_duplicated).count).to eq 1
    end

    it 'returns unprocessable entity when duplication fails' do
      allow_any_instance_of(StorageLocation).to receive(:duplicate!).and_return(false)

      post :duplicate, params: { id: location.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'renders 403 without manage permission' do
      location
      make_team_viewer!

      expect { post :duplicate, params: { id: location.id }, format: :json }
        .not_to change(StorageLocation, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST move' do
    let(:destination) { create_location(name: 'Destination') }

    it 'moves location to another parent and logs activity' do
      post :move, params: { id: container.id, destination_storage_location_id: destination.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(container.reload.parent).to eq destination
      activity = Activity.find_by(type_of: :container_storage_location_moved)
      expect(activity.values['message_items']['storage_location_original']['id']).to eq location.id
    end

    it 'moves location to root' do
      post :move, params: { id: container.id, destination_storage_location_id: 'root_storage_location' },
                  format: :json

      expect(response).to have_http_status(:success)
      expect(container.reload.parent).to be_nil
    end

    it 'returns bad request when moving into own child' do
      post :move, params: { id: location.id, destination_storage_location_id: container.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(location.reload.parent).to be_nil
    end

    it 'renders 403 without manage permission' do
      make_team_viewer!

      post :move, params: { id: container.id, destination_storage_location_id: destination.id }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(container.reload.parent).to eq location
    end
  end

  describe 'GET tree' do
    it 'returns nested locations tree' do
      container
      create_location(name: 'Shelf', parent: location)

      get :tree, params: { container: 'true', team_id: team.id }, format: :json

      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body['movable_to_root']).to be true
      root = body['locations'].first
      expect(root['storage_location']['name']).to eq 'Freezer'
      expect(root['can_manage']).to be true
      expect(root['children'].map { |c| c['storage_location']['name'] }).to eq %w(Box Shelf)
    end

    it 'excludes containers by default' do
      container

      get :tree, format: :json

      root = JSON.parse(response.body)['locations'].first
      expect(root['children']).to eq []
    end
  end

  describe 'GET available_positions' do
    it 'returns free grid positions' do
      get :available_positions, params: { id: container.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['positions']).to eq('1' => [1, 2], '2' => [1, 2])
    end

    it 'renders 404 for a location of another team' do
      foreign = create_location(name: 'Foreign', location_team: create(:team))

      get :available_positions, params: { id: foreign.id }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST unassign_rows' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:row) { create :repository_row, repository: repository, created_by: user }
    let!(:assignment) do
      StorageLocationRepositoryRow.create!(storage_location: container, repository_row: row,
                                           metadata: { position: [1, 2] }, created_by: user)
    end

    it 'discards assignments and logs activities' do
      post :unassign_rows, params: { id: container.id, ids: [assignment.id] }, format: :json

      expect(response).to have_http_status(:success)
      expect(StorageLocationRepositoryRow.with_discarded.find(assignment.id)).to be_discarded
      activity = Activity.find_by(type_of: :storage_location_repository_row_deleted)
      expect(activity.values['message_items']['position']).to eq 'A2'
    end

    it 'renders 403 without manage permission' do
      make_team_viewer!

      post :unassign_rows, params: { id: container.id, ids: [assignment.id] }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(assignment.reload).not_to be_discarded
    end
  end

  describe 'GET export_container' do
    it 'sends an xlsx file' do
      allow_any_instance_of(StorageLocations::ExportService).to receive(:to_xlsx).and_return('xlsx-data')

      get :export_container, params: { id: container.id }

      expect(response).to have_http_status(:success)
      expect(response.body).to eq 'xlsx-data'
      expect(response.headers['Content-Disposition']).to include("Box_export_#{Date.current}.xlsx")
    end
  end

  describe 'POST import_container' do
    let(:import_service) { instance_double(StorageLocations::ImportService) }

    before do
      allow(StorageLocations::ImportService).to receive(:new).and_return(import_service)
    end

    it 'imports items and logs activity' do
      allow(import_service).to receive(:import_items)
        .and_return({ status: :ok, assigned_count: 2, unassigned_count: 1 })

      post :import_container, params: { id: container.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to include('assigned_count' => 2)
      activity = Activity.find_by(type_of: :container_storage_location_imported)
      expect(activity.values['message_items']['assigned_count']).to eq '2'
    end

    it 'does not log activity when nothing changed' do
      allow(import_service).to receive(:import_items)
        .and_return({ status: :ok, assigned_count: 0, unassigned_count: 0 })

      expect { post :import_container, params: { id: container.id }, format: :json }
        .not_to(change { Activity.count })
      expect(response).to have_http_status(:success)
    end

    it 'returns unprocessable entity on import error' do
      allow(import_service).to receive(:import_items).and_return({ status: :error, message: 'Bad file' })

      post :import_container, params: { id: container.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['message']).to eq 'Bad file'
    end

    it 'renders 403 without manage permission' do
      make_team_viewer!

      post :import_container, params: { id: container.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST actions_toolbar' do
    it 'returns toolbar actions for selected locations' do
      post :actions_toolbar, params: { items: [{ id: location.id }].to_json }, format: :json

      expect(response).to have_http_status(:success)
      actions = JSON.parse(response.body)['actions'].map { |a| a['name'] }
      expect(actions).to include('edit', 'duplicate')
    end
  end
end
