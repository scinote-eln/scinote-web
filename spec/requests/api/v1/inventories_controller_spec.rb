# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::InventoriesController", type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 2, created_by: @user)
    create(:user_team, user: @user, team: @teams.first, role: 2)

    # valid_inventories
    create(:repository, name: Faker::Name.unique.name,
            created_by: @user, team: @teams.first)
    create(:repository, name: Faker::Name.unique.name,
            created_by: @user, team: @teams.first)

    # unaccessable_inventories
    create(:repository, name: Faker::Name.unique.name,
                created_by: @user, team: @teams.second)
    create(:repository, name: Faker::Name.unique.name,
                created_by: @user, team: @teams.second)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET inventories, #index' do
    it 'Response with correct inventories' do
      hash_body = nil
      get api_v1_team_inventories_path(team_id: @teams.first.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@teams.first.repositories,
               each_serializer: Api::V1::InventorySerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventories_path(team_id: @teams.second.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match({})
    end
  end

  describe 'GET inventory, #show' do
    it 'When valid request, user is member of the team' do
      hash_body = nil
      get api_v1_team_inventory_path(team_id: @teams.first.id,
                                id: @teams.first.repositories.first.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@teams.first.repositories.first,
               serializer: Api::V1::InventorySerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_path(team_id: @teams.second.id,
                                id: @teams.second.repositories.first.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match({})
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      get api_v1_team_inventory_path(team_id: @teams.first.id, id: 123),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match({})
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      get api_v1_team_inventory_path(team_id: @teams.first.id,
                                id: @teams.second.repositories.first.id),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match({})
    end
  end

  describe 'DELETE inventories, #destroy' do
    it 'Destroys inventory' do
      deleted_id = @teams.first.repositories.last.id
      delete api_v1_team_inventory_path(
        id: deleted_id,
        team_id: @teams.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(200)
      expect(Repository.where(id: deleted_id)).to_not exist
      expect(RepositoryRow.where(repository: deleted_id).count).to equal 0
      expect(RepositoryColumn.where(repository: deleted_id).count).to equal 0
    end

    it 'Invalid request, non existing inventory' do
      delete api_v1_team_inventory_path(
        id: 123,
        team_id: @teams.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
    end

    it 'When invalid request, repository from another team' do
      deleted_id = @teams.first.repositories.last.id
      delete api_v1_team_inventory_path(
        id: deleted_id,
        team_id: @teams.second.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect(Repository.where(id: deleted_id)).to exist
    end
  end
end
