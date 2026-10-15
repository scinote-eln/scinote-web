# frozen_string_literal: true

require 'rails_helper'

describe StorageLocationRepositoryRowsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:viewer_role) { create :viewer_role }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:row) { create :repository_row, repository: repository, created_by: user, name: 'Sample A' }
  let(:other_row) { create :repository_row, repository: repository, created_by: user, name: 'Sample B' }
  let(:grid_box) do
    StorageLocation.create!(name: 'Grid box', container: true, team: team, created_by: user,
                            metadata: { display_type: 'grid', dimensions: [2, 3] })
  end
  let(:plain_box) do
    StorageLocation.create!(name: 'Plain box', container: true, team: team, created_by: user, metadata: {})
  end

  def assign(location, repository_row, position = nil)
    StorageLocationRepositoryRow.create!(storage_location: location, repository_row: repository_row,
                                         metadata: position ? { position: position } : {}, created_by: user)
  end

  def make_team_viewer!
    team.user_assignments.find_by(user: user).update!(user_role: viewer_role)
  end

  before do
    allow(StorageLocation).to receive(:storage_locations_enabled?).and_return(true)
  end

  describe 'GET index' do
    it 'returns rows assigned to the grid location' do
      assign(grid_box, row, [1, 2])

      get :index, params: { storage_location_id: grid_box.id }, as: :json

      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body['data'].first['attributes']).to include('row_name' => 'Sample A', 'position_formatted' => 'A2')
      expect(body['meta']).to be_nil
    end

    it 'returns pagination meta for non grid location' do
      assign(plain_box, row)

      get :index, params: { storage_location_id: plain_box.id, page: 1, per_page: 10 }, as: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['meta']).to include('total_count' => 1)
    end

    it 'renders 404 for a location of another team' do
      foreign = StorageLocation.create!(name: 'Foreign', container: true, team: create(:team),
                                        created_by: user, metadata: {})

      get :index, params: { storage_location_id: foreign.id }, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'renders 403 when storage locations are disabled' do
      allow(StorageLocation).to receive(:storage_locations_enabled?).and_return(false)

      get :index, params: { storage_location_id: grid_box.id }, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST create' do
    it 'assigns a row to grid positions and logs activity' do
      expect do
        post :create, params: { storage_location_id: grid_box.id, repository_row_id: row.id,
                                positions: [[1, 1], [2, 3]] }, as: :json
      end.to change(StorageLocationRepositoryRow, :count).by(2)

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['data'].map { |d| d['attributes']['position_formatted'] })
        .to match_array %w(A1 B3)
      activity = Activity.find_by(type_of: :storage_location_repository_row_created)
      expect(activity.values['message_items']['position']).to eq 'A1, B3'
    end

    it 'replaces an occupied position' do
      occupied = assign(grid_box, other_row, [1, 1])

      post :create, params: { storage_location_id: grid_box.id, repository_row_id: row.id,
                              positions: [[1, 1, { occupied: true, id: occupied.id }]] }, as: :json

      expect(response).to have_http_status(:success)
      expect(StorageLocationRepositoryRow.with_discarded.find(occupied.id)).to be_discarded
      expect(grid_box.storage_location_repository_rows.pluck(:repository_row_id)).to eq [row.id]
    end

    it 'returns errors for a duplicate position' do
      assign(grid_box, other_row, [1, 1])

      expect do
        post :create, params: { storage_location_id: grid_box.id, repository_row_id: row.id,
                                positions: [[1, 1]] }, as: :json
      end.not_to change(StorageLocationRepositoryRow, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to be_present
    end

    it 'assigns a row to a location without grid' do
      post :create, params: { storage_location_id: plain_box.id, repository_row_id: row.id }, as: :json

      expect(response).to have_http_status(:success)
      expect(plain_box.repository_rows).to eq [row]
    end

    it 'returns errors when row is already in a location without grid' do
      assign(plain_box, row)

      post :create, params: { storage_location_id: plain_box.id, repository_row_id: row.id }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(plain_box.storage_location_repository_rows.count).to eq 1
    end

    it 'renders 403 without manage permission' do
      make_team_viewer!

      post :create, params: { storage_location_id: plain_box.id, repository_row_id: row.id }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(plain_box.storage_location_repository_rows.count).to eq 0
    end

    # Current behaviour: the controller never checks read access to the repository row itself,
    # so a row from an inventory of a different team (not shared) can be assigned.
    it 'allows assigning an inventory item from a foreign team (no row permission check)' do
      foreign_row = create :repository_row, repository: create(:repository, team: create(:team))

      post :create, params: { storage_location_id: plain_box.id, repository_row_id: foreign_row.id }, as: :json

      expect(response).to have_http_status(:success)
      expect(plain_box.repository_rows).to eq [foreign_row]
    end
  end

  describe 'PUT update' do
    let!(:assignment) { assign(grid_box, row, [1, 1]) }

    it 'updates the position and logs activity' do
      put :update, params: { id: assignment.id, storage_location_id: grid_box.id, repository_row_id: row.id,
                             metadata: { position: [2, 2] } }, as: :json

      expect(response).to have_http_status(:success)
      expect(assignment.reload.human_readable_position).to eq 'B2'
      expect(Activity.find_by(type_of: :storage_location_repository_row_moved).values['message_items']['position'])
        .to eq 'B2'
    end

    it 'returns errors for an occupied position' do
      assign(grid_box, other_row, [2, 2])

      put :update, params: { id: assignment.id, storage_location_id: grid_box.id, repository_row_id: row.id,
                             metadata: { position: [2, 2] } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(assignment.reload.human_readable_position).to eq 'A1'
    end

    it 'renders 403 without manage permission' do
      make_team_viewer!

      put :update, params: { id: assignment.id, storage_location_id: grid_box.id, repository_row_id: row.id,
                             metadata: { position: [2, 2] } }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(assignment.reload.human_readable_position).to eq 'A1'
    end
  end

  describe 'POST move' do
    let!(:assignment) { assign(grid_box, row, [1, 1]) }
    let(:target_box) do
      StorageLocation.create!(name: 'Target', container: true, team: team, created_by: user,
                              metadata: { display_type: 'grid', dimensions: [1, 1] })
    end

    it 'moves the row to another grid location' do
      post :move, params: { id: assignment.id, storage_location_id: target_box.id, repository_row_id: row.id,
                            positions: [[1, 1]] }, as: :json

      expect(response).to have_http_status(:success)
      expect(StorageLocationRepositoryRow.with_discarded.find(assignment.id)).to be_discarded
      expect(target_box.repository_rows).to eq [row]
      activity = Activity.find_by(type_of: :storage_location_repository_row_moved)
      expect(activity.values['message_items']['position_original']).to eq 'A1'
    end

    it 'moves the row to a location without grid' do
      post :move, params: { id: assignment.id, storage_location_id: plain_box.id, repository_row_id: row.id },
                  as: :json

      expect(response).to have_http_status(:success)
      expect(plain_box.repository_rows).to eq [row]
    end

    it 'returns errors and rolls back when target position is invalid' do
      post :move, params: { id: assignment.id, storage_location_id: target_box.id, repository_row_id: row.id,
                            positions: [[]] }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(assignment.reload).not_to be_discarded
    end

    it 'renders 403 without manage permission' do
      make_team_viewer!

      post :move, params: { id: assignment.id, storage_location_id: plain_box.id, repository_row_id: row.id },
                  as: :json

      expect(response).to have_http_status(:forbidden)
      expect(assignment.reload).not_to be_discarded
    end
  end

  describe 'DELETE destroy' do
    let!(:assignment) { assign(grid_box, row, [1, 3]) }

    it 'discards the assignment and logs activity' do
      delete :destroy, params: { id: assignment.id, storage_location_id: grid_box.id, repository_row_id: row.id },
                       as: :json

      expect(response).to have_http_status(:success)
      expect(StorageLocationRepositoryRow.with_discarded.find(assignment.id)).to be_discarded
      expect(Activity.find_by(type_of: :storage_location_repository_row_deleted).values['message_items']['position'])
        .to eq 'A3'
    end

    it 'returns errors when discard fails' do
      allow_any_instance_of(StorageLocationRepositoryRow).to receive(:discard).and_return(false)

      delete :destroy, params: { id: assignment.id, storage_location_id: grid_box.id, repository_row_id: row.id },
                       as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'renders 403 without manage permission' do
      make_team_viewer!

      delete :destroy, params: { id: assignment.id, storage_location_id: grid_box.id, repository_row_id: row.id },
                       as: :json

      expect(response).to have_http_status(:forbidden)
      expect(assignment.reload).not_to be_discarded
    end
  end

  describe 'POST actions_toolbar' do
    let!(:assignment) { assign(grid_box, row, [1, 1]) }

    it 'returns unassign and move actions' do
      post :actions_toolbar, params: { storage_location_id: grid_box.id, items: [{ id: assignment.id }].to_json },
                             as: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['actions'].map { |a| a['name'] }).to eq %w(unassign move)
    end

    it 'returns no actions for viewers' do
      make_team_viewer!

      post :actions_toolbar, params: { storage_location_id: grid_box.id, items: [{ id: assignment.id }].to_json },
                             as: :json

      expect(JSON.parse(response.body)['actions']).to eq []
    end
  end
end
