# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::InventoryItemsController', type: :request do
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

    text_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryTextValue)
    list_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryListValue)
    list_item =
      create(:repository_list_item, repository: @valid_inventory,
             repository_column: list_column, data: Faker::Name.unique.name)
    file_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryAssetValue)
    asset = create(:asset)

    create_list(:repository_row, 100, repository: @valid_inventory)

    @valid_inventory.repository_rows.each do |row|
      create(:repository_text_value,
             data: Faker::Name.name,
             repository_cell_attributes:
               { repository_row: row, repository_column: text_column })
      create(:repository_list_value, repository_list_item: list_item,
             repository_cell_attributes:
               { repository_row: row, repository_column: list_column })
      create(:repository_asset_value, asset: asset,
             repository_cell_attributes:
               { repository_row: row, repository_column: file_column })
    end

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET inventory_items, #index' do
    it 'Response with correct inventory items, default per page' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @teams.first.id,
        inventory_id: @teams.first.repositories.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_inventory.repository_rows.limit(10),
               each_serializer: Api::V1::InventoryItemSerializer,
               include: :inventory_cells)
          .as_json[:data]
      )
      expect(hash_body[:included]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_inventory.repository_rows.limit(10),
               each_serializer: Api::V1::InventoryItemSerializer,
               include: :inventory_cells)
          .as_json[:included]
      )
    end

    it 'Response with correct inventory items, 100 per page' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @teams.first.id,
        inventory_id: @teams.first.repositories.first.id
      ), params: { page: { size: 100 } }, headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_inventory.repository_rows.limit(100),
               each_serializer: Api::V1::InventoryItemSerializer,
               include: :inventory_cells)
          .as_json[:data]
      )
      expect(hash_body[:included]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_inventory.repository_rows.limit(100),
               each_serializer: Api::V1::InventoryItemSerializer,
               include: :inventory_cells)
          .as_json[:included]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @teams.second.id,
        inventory_id: @teams.second.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match({})
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @teams.first.id,
        inventory_id: 123
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match({})
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @teams.first.id,
        inventory_id: @teams.second.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match({})
    end
  end

  describe 'PATCH inventory_items, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @inventory_item = ActiveModelSerializers::SerializableResource.new(
        RepositoryRow.last,
        serializer: Api::V1::InventoryItemSerializer,
        include: :inventory_cells
      )
    end

    it 'Response with correctly updated inventory item for name field' do
      hash_body = nil
      updated_inventory_item = @inventory_item.as_json[:data]
      updated_inventory_item[:attributes][:name] = Faker::Name.unique.name
      patch api_v1_team_inventory_item_path(
        id: RepositoryRow.last.id,
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id
      ), params: { data: updated_inventory_item }.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data].to_json).to match(updated_inventory_item.to_json)
    end

    it 'Response with correctly updated inventory item for list item column' do
      hash_body = nil
      updated_inventory_item = @inventory_item.as_json[:included]
      updated_inventory_item.each do |cell|
                                    attributes = cell[:attributes]
                                    if attributes[:value_type] == 'list'
                                        cell[:attributes] = {
                                          :value_type => "list",
                                          :value => Faker::Name.unique.name,
                                          :column_id => 2
                                        }
                                    end
                                  end
      puts updated_inventory_item
      patch api_v1_team_inventory_item_path(
        id: RepositoryRow.last.id,
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id
      ), params: @inventory_item.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:included].to_json).to match(updated_inventory_item.to_json)
    end

    # it 'Response with correctly updated inventory item for text item column' do
    #   hash_body = nil
    #   updated_inventory_item = @inventory_item.as_json[:included]
    #   updated_inventory_item.each do |cell|
    #                                 attributes = cell[:attributes]
    #                                 if attributes[:value_type] == 'text'
    #                                     attributes[:value] = Faker::Name.unique.name
    #                                 end
    #                               end
    #   patch api_v1_team_inventory_item_path(
    #     id: RepositoryRow.last.id,
    #     team_id: @teams.first.id,
    #     inventory_id: @valid_inventory.id
    #   ), params: @inventory_item.to_json,
    #   headers: @valid_headers
    #   expect(response).to have_http_status 200
    #   expect { hash_body = json }.not_to raise_exception
    #   expect(hash_body[:included].to_json).to match(updated_inventory_item.to_json)
    # end
  end
end
