# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::InventoryColumnsController', type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 2, created_by: @user)
    create(:user_team, user: @user, team: @teams.first, role: 2)

    # valid_inventory
    @valid_inventory = create(:repository, name: Faker::Name.unique.name,
                              created_by: @user, team: @teams.first)

    # unaccessable_inventory
    create(:repository, name: Faker::Name.unique.name,
                created_by: @user, team: @teams.second)

    create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryTextValue)
    list_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryListValue)
    create(:repository_list_item, repository: @valid_inventory,
             repository_column: list_column, data: Faker::Name.unique.name)
    create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryAssetValue)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET inventory_columns, #index' do
    it 'Response with correct inventory items, default per page' do
      hash_body = nil
      get api_v1_team_inventory_columns_path(
        team_id: @teams.first.id,
        inventory_id: @teams.first.repositories.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_inventory.repository_columns.limit(10),
               each_serializer: Api::V1::InventoryColumnSerializer,
               include: :inventory_columns)
          .as_json[:data]
      )
      expect(hash_body[:included]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_inventory.repository_columns.limit(10),
               each_serializer: Api::V1::InventoryColumnSerializer,
               include: :inventory_list_items)
          .as_json[:included]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_columns_path(
        team_id: @teams.second.id,
        inventory_id: @teams.second.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match({})
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      get api_v1_team_inventory_columns_path(
        team_id: @teams.first.id,
        inventory_id: 123
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match({})
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      get api_v1_team_inventory_columns_path(
        team_id: @teams.first.id,
        inventory_id: @teams.second.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match({})
    end
  end
end
