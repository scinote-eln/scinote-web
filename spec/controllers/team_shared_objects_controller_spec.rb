# frozen_string_literal: true

require 'rails_helper'

describe TeamSharedObjectsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { skip_experiment: true, skip_my_module: true }

  let!(:repository) { create :repository, team: team, created_by: user }
  let!(:target_team) { create :team, created_by: user, name: 'Target team' }
  let(:object_params) { { object_type: 'Repository', object_id: repository.id } }

  def activity_count(type)
    Activity.where(type_of: type).count
  end

  describe 'POST update for a repository' do
    def share(team_share_params, extra = {})
      # empty arrays do not survive form encoding, so send a placeholder entry that shares nothing
      post :update, params: object_params.merge(team_share_params: team_share_params.presence || [{ id: -1 }])
                                         .merge(extra)
    end

    it 'shares privately with read permission and logs an activity' do
      expect { share([{ id: target_team.id, private_shared_with: 'true' }]) }
        .to change { activity_count(:share_inventory) }.by(1)
      expect(response).to have_http_status(:no_content)
      shared = repository.team_shared_objects.find_by(team: target_team)
      expect(shared).to be_shared_read
    end

    it 'shares privately with write permission' do
      share([{ id: target_team.id, private_shared_with: 'true', private_shared_with_write: 'true' }])
      expect(repository.team_shared_objects.find_by(team: target_team)).to be_shared_write
    end

    it 'logs an update activity when the permission changes' do
      create :team_shared_object, :read, team: target_team, shared_object: repository
      expect do
        share([{ id: target_team.id, private_shared_with: 'true', private_shared_with_write: 'true' }])
      end.to change { activity_count(:update_share_inventory) }.by(1)
      expect(repository.team_shared_objects.find_by(team: target_team)).to be_shared_write
    end

    it 'does not log an activity when nothing changes' do
      create :team_shared_object, :read, team: target_team, shared_object: repository
      expect { share([{ id: target_team.id, private_shared_with: 'true' }]) }
        .not_to(change { Activity.count })
    end

    it 'unshares teams that are not in the list and logs an activity' do
      create :team_shared_object, :read, team: target_team, shared_object: repository
      expect { share([{ id: target_team.id }]) }
        .to change { activity_count(:unshare_inventory) }.by(1)
      expect(repository.reload.team_shared_objects).to be_empty
    end

    it 'shares with all teams (read) and logs an activity' do
      expect { share([], select_all_teams: 'true') }
        .to change { activity_count(:share_inventory_with_all) }.by(1)
      expect(repository.reload).to be_shared_read
    end

    it 'shares with all teams (write)' do
      share([], select_all_teams: 'true', select_all_write_permission: 'true')
      expect(repository.reload).to be_shared_write
    end

    it 'updates the global permission level and logs an activity' do
      repository.update!(permission_level: :shared_read)
      expect { share([], select_all_teams: 'true', select_all_write_permission: 'true') }
        .to change { activity_count(:update_share_with_all_permission_level) }.by(1)
    end

    it 'drops private shares and logs an activity when global sharing is switched on' do
      create :team_shared_object, :read, team: target_team, shared_object: repository
      share([{ id: target_team.id, private_shared_with: 'true' }], select_all_teams: 'true')
      expect(repository.reload).to be_shared_read
    end

    it 'stops global sharing and logs an activity' do
      repository.update!(permission_level: :shared_read)
      expect { share([]) }.to change { activity_count(:unshare_inventory_with_all) }.by(1)
      expect(repository.reload).to be_not_shared
    end

    it 'is forbidden for a repository viewer' do
      repository.user_assignments.update(user_role: viewer_role)
      expect { share([{ id: target_team.id, private_shared_with: 'true' }]) }
        .not_to change(TeamSharedObject, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden to set write permissions when the object is not write shareable' do
      allow_any_instance_of(Repository).to receive(:shareable_write?).and_return(false)
      share([{ id: target_team.id, private_shared_with: 'true' }], write_permissions: [target_team.id])
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 for an unknown repository' do
      post :update, params: { object_type: 'Repository', object_id: -1, team_share_params: [] }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an unsupported object type' do
      post :update, params: { object_type: 'Project', object_id: project.id, team_share_params: [] }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for a repository of a team the user cannot read' do
      foreign = create :repository
      post :update, params: { object_type: 'Repository', object_id: foreign.id, team_share_params: [] }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST update for a storage location' do
    let!(:location) do
      StorageLocation.create!(name: 'Freezer', team: team, created_by: user)
    end
    let(:location_params) { { object_type: 'StorageLocation', object_id: location.id } }

    before { allow(StorageLocation).to receive(:storage_locations_enabled?).and_return(true) }

    it 'shares the location and logs an activity' do
      expect do
        post :update, params: location_params.merge(team_share_params: [{ id: target_team.id,
                                                                          private_shared_with: 'true' }])
      end.to change { activity_count(:storage_location_shared) }.by(1)
      expect(location.team_shared_objects.find_by(team: target_team)).to be_shared_read
    end

    it 'updates and unshares the location' do
      post :update, params: location_params.merge(team_share_params: [{ id: target_team.id,
                                                                        private_shared_with: 'true' }])
      expect do
        post :update, params: location_params.merge(team_share_params: [{ id: target_team.id,
                                                                          private_shared_with: 'true',
                                                                          private_shared_with_write: 'true' }])
      end.to change { activity_count(:storage_location_sharing_updated) }.by(1)
      expect do
        post :update, params: location_params.merge(team_share_params: [{ id: -1 }])
      end.to change { activity_count(:storage_location_unshared) }.by(1)
      expect(location.reload.team_shared_objects).to be_empty
    end

    it 'uses container activity types for containers' do
      container = StorageLocation.create!(name: 'Box', container: true, parent: location, team: team,
                                          created_by: user, metadata: { display_type: 'grid', dimensions: [2, 2] })
      allow_any_instance_of(StorageLocation).to receive(:root?).and_return(true)
      expect do
        post :update, params: { object_type: 'StorageLocation', object_id: container.id,
                                team_share_params: [{ id: target_team.id, private_shared_with: 'true' }] }
      end.to change { activity_count(:container_storage_location_shared) }.by(1)
    end

    it 'is forbidden for non root locations' do
      child = StorageLocation.create!(name: 'Shelf', parent: location, team: team, created_by: user)
      post :update, params: { object_type: 'StorageLocation', object_id: child.id, team_share_params: [] }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET shareable_teams' do
    it 'lists teams except the owner team with share state' do
      create :team_shared_object, :write, team: target_team, shared_object: repository
      get :shareable_teams, params: object_params, format: :json
      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)['data']
      expect(data.pluck('id')).not_to include(team.id.to_s)
      entry = data.find { |t| t['id'] == target_team.id.to_s }
      expect(entry['attributes']).to include('name' => 'Target team', 'private_shared_with' => true,
                                             'private_shared_with_write' => true)
    end

    it 'omits unreadable teams that are not shared with' do
      hidden = create :team
      get :shareable_teams, params: object_params, format: :json
      expect(JSON.parse(response.body)['data'].pluck('id')).not_to include(hidden.id.to_s)
    end

    it 'returns 404 for an unknown object' do
      get :shareable_teams, params: { object_type: 'Repository', object_id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
