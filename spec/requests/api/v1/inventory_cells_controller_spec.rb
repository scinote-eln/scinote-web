# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::InventoryCellsController', type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)
    @wrong_team = create(:team, created_by: @user)
    create(:user_team, user: @user, team: @team, role: 2)

    # valid_inventory
    @valid_inventory = create(:repository, name: Faker::Name.unique.name,
                              created_by: @user, team: @team)

    # unaccessable_inventory
    @wrong_inventory = create(:repository, name: Faker::Name.unique.name,
                              created_by: @user, team: @wrong_team)
    create(:repository_row, repository: @wrong_inventory)

    @text_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryTextValue)
    @list_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryListValue)
    list_item =
      create(:repository_list_item, repository: @valid_inventory,
             repository_column: @list_column, data: Faker::Name.unique.name)
    second_list_item =
      create(:repository_list_item, repository: @valid_inventory,
             repository_column: @list_column, data: Faker::Name.unique.name)
    @file_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryAssetValue)
    asset = create(:asset)

    @valid_item = create(:repository_row, repository: @valid_inventory)

    create(:repository_text_value,
           data: Faker::Name.name,
           repository_cell_attributes:
             { repository_row: @valid_item, repository_column: @text_column })
    create(:repository_list_value, repository_list_item: list_item,
           repository_cell_attributes:
             { repository_row: @valid_item, repository_column: @list_column })
    create(:repository_asset_value, asset: asset,
           repository_cell_attributes:
             { repository_row: @valid_item, repository_column: @file_column })

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id),
        'Content-Type': 'application/json' }

    @valid_text_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @text_column.id,
          value: Faker::Name.unique.name
        }
      }
    }
    @valid_list_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @list_column.id,
          value: list_item.id
        }
      }
    }
    @valid_file_body = {
      data: {
        type: 'inventory_cells',
        attributes: {
          column_id: @file_column.id,
          value: {
            file_name: 'test.txt',
            file_data: 'data:text/plain;base64,dGVzdAo='
          }
        }
      }
    }
    @update_text_body = {
      data: {
        id: @valid_item.repository_cells
                       .where(repository_column: @text_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @text_column.id,
          value: Faker::Name.unique.name
        }
      }
    }
    @update_list_body = {
      data: {
        id: @valid_item.repository_cells
                       .where(repository_column: @list_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @list_column.id,
          value: second_list_item.id
        }
      }
    }
    @update_file_body = {
      data: {
        id: @valid_item.repository_cells
                       .where(repository_column: @file_column).first.id,
        type: 'inventory_cells',
        attributes: {
          column_id: @file_column.id,
          value: {
            file_name: 'test.txt',
            file_data: 'data:text/plain;base64,dGVzdDIK='
          }
        }
      }
    }
  end

  describe 'GET inventory_cells, #index' do
    it 'Response with correct inventory cells' do
      hash_body = nil
      get api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_item.repository_cells,
               each_serializer: Api::V1::InventoryCellSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_item_cells_path(
        team_id: @wrong_team.id,
        inventory_id: @wrong_inventory.id,
        item_id: 999
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing item' do
      hash_body = nil
      get api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory,
        item_id: 999
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET inventory_cells, #show' do
    it 'Response with correct inventory cell' do
      hash_body = nil
      get api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_item.repository_cells.first,
               serializer: Api::V1::InventoryCellSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_item_cell_path(
        team_id: @wrong_team.id,
        inventory_id: @wrong_inventory.id,
        item_id: 999,
        id: 999
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing cell' do
      hash_body = nil
      get api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory,
        item_id: @valid_item,
        id: 999
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST inventory_cells, #create' do
    it 'Response with correct inventory cell, text cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(RepositoryCell.last,
               serializer: Api::V1::InventoryCellSerializer)
          .as_json[:data]
      )
    end

    it 'Response with correct inventory cell, list cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_list_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(RepositoryCell.last,
               serializer: Api::V1::InventoryCellSerializer)
          .as_json[:data]
      )
    end

    it 'Response with correct inventory cell, file cell' do
      hash_body = nil
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: @valid_file_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(RepositoryCell.last,
               serializer: Api::V1::InventoryCellSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, payload mismatches column type' do
      hash_body = nil
      invalid_file_body = @valid_file_body.dup
      invalid_file_body[:data][:attributes][:value] = 'abc'
      empty_item = create(:repository_row, repository: @valid_inventory)
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: empty_item.id
      ), params: invalid_file_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 400
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      post api_v1_team_inventory_item_cells_path(
        team_id: @team.id,
        inventory_id: -1,
        item_id: @valid_item.id
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      post api_v1_team_inventory_item_cells_path(
        team_id: @wrong_team.id,
        inventory_id: @wrong_inventory.id,
        item_id: 999
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      post api_v1_team_inventory_items_path(
        team_id: @team.id,
        inventory_id: @wrong_inventory.id,
        item_id: -1
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'PUT inventory_cells, #update' do
    it 'Response with correct inventory cell, text cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells
                       .where(repository_column: @text_column).first.id
      ), params: @update_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_item.repository_cells
                          .where(repository_column: @text_column).first,
               serializer: Api::V1::InventoryCellSerializer)
          .as_json[:data]
      )
    end

    it 'Response with correct inventory cell, list cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells
                       .where(repository_column: @list_column).first.id
      ), params: @update_list_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_item.repository_cells
                          .where(repository_column: @list_column).first,
               serializer: Api::V1::InventoryCellSerializer)
          .as_json[:data]
      )
    end

    it 'Response with correct inventory cell, file cell' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells
                       .where(repository_column: @file_column).first.id
      ), params: @update_file_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_item.repository_cells
                         .where(repository_column: @file_column).first,
               serializer: Api::V1::InventoryCellSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, payload mismatches column type' do
      hash_body = nil
      invalid_file_body = @valid_file_body.dup
      invalid_file_body[:data][:attributes][:value] = 'abc'
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id,
        id: @valid_item.repository_cells
                       .where(repository_column: @file_column).first.id
      ), params: invalid_file_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 400
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @team.id,
        inventory_id: -1,
        item_id: @valid_item.id,
        id: -1
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      patch api_v1_team_inventory_item_cell_path(
        team_id: @wrong_team.id,
        inventory_id: @wrong_inventory.id,
        item_id: -1,
        id: -1
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      patch api_v1_team_inventory_item_path(
        team_id: @team.id,
        inventory_id: @wrong_inventory.id,
        item_id: -1,
        id: -1
      ), params: @valid_text_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'DELETE inventory_cells, #destroy' do
    it 'Destroys inventory cell' do
      deleted_id = @valid_item.repository_cells.last.id
      delete api_v1_team_inventory_item_cell_path(
        id: deleted_id,
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id
      ), headers: @valid_headers
      expect(response).to have_http_status(200)
      expect(RepositoryCell.where(id: deleted_id)).to_not exist
    end

    it 'Invalid request, non existing inventory item' do
      deleted_id = RepositoryCell.last.id + 1
      delete api_v1_team_inventory_item_cell_path(
        id: deleted_id,
        team_id: @team.id,
        inventory_id: @valid_inventory.id,
        item_id: @valid_item.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
    end
  end
end
