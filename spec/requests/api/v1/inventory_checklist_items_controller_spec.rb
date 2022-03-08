# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::InventoryChecklistItemsController', type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 2, created_by: @user)
    create(:user_team, user: @user, team: @teams.first, role: 2)

    @valid_inventory = create(:repository, name: Faker::Name.unique.name,
                              created_by: @user, team: @teams.first)

    @wrong_inventory = create(:repository, name: Faker::Name.unique.name,
                              created_by: @user, team: @teams.second)
    create(:repository_column, name: Faker::Name.unique.name,
           repository: @wrong_inventory, data_type: :RepositoryTextValue)

    @text_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryTextValue)
    @checklist_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryChecklistValue)
    @wrong_checklist_column = create(:repository_column,
      name: Faker::Name.unique.name,
      repository: @wrong_inventory,
      data_type: :RepositoryChecklistValue)
    create_list(:repository_checklist_item, 10, repository_column: @checklist_column)
    create(:repository_checklist_item, repository_column: @wrong_checklist_column)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET inventory_checklist_items, #index' do
    it 'Response with correct inventory list items, default per page' do
      hash_body = nil
      get api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.first.id,
        inventory_id: @teams.first.repositories.first.id,
        column_id: @checklist_column.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@checklist_column.repository_checklist_items.limit(10),
                 each_serializer: Api::V1::InventoryChecklistItemSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_column_checklist_items_path(
        team_id: @wrong_inventory.team.id,
        inventory_id: @wrong_inventory.id,
        column_id: @wrong_inventory.repository_columns.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      get api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.first.id,
        inventory_id: 123,
        column_id: 999
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      get api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.first.id,
        inventory_id: @wrong_inventory.id,
        column_id: @checklist_column.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, items from text column' do
      hash_body = nil
      get api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @text_column.id
      ), headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end
  end

  describe 'GET inventory_checklist_items, #show' do
    it 'Response with correct inventory list item' do
      hash_body = nil
      get api_v1_team_inventory_column_checklist_item_path(
        id: @checklist_column.repository_checklist_items.first.id,
        team_id: @teams.first.id,
        inventory_id: @teams.first.repositories.first.id,
        column_id: @checklist_column.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@checklist_column.repository_checklist_items.first,
                 serializer: Api::V1::InventoryChecklistItemSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, non existing list item' do
      hash_body = nil
      get api_v1_team_inventory_column_checklist_item_path(
        id: 999,
        team_id: @teams.first.id,
        inventory_id: @teams.first.repositories.first.id,
        column_id: @checklist_column.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, list item from another column' do
      hash_body = nil
      get api_v1_team_inventory_column_checklist_items_path(
        id: @wrong_checklist_column.repository_checklist_items.first.id,
        team_id: @teams.first.id,
        inventory_id: @wrong_inventory.id,
        column_id: @checklist_column.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST inventory_checklist_item, #create' do
    before :all do
      @valid_headers['Content-Type'] = 'application/vnd.api+json'
      @request_body = {
        data: {
          type: 'inventory_checklist_items',
          attributes: { data: Faker::Name.unique.name }
        }
      }
    end

    it 'Response with correct inventory list item' do
      hash_body = nil
      post api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryChecklistItem.last, serializer: Api::V1::InventoryChecklistItemSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      post api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.second.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 403
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      post api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.first.id,
        inventory_id: 123,
        column_id: @checklist_column
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 404
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      post api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.first.id,
        inventory_id: @wrong_inventory.id,
        column_id: @checklist_column
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, incorrect type' do
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data][:type] = 'repository_rows'
      hash_body = nil
      post api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, missing type param' do
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data].delete(:type)
      hash_body = nil
      post api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, missing attributes values' do
      hash_body = nil
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data][:attributes].delete(:data)
      post api_v1_team_inventory_column_checklist_items_path(
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end
  end

  describe 'PUT inventory_checklist_item, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/vnd.api+json'
      @request_body = {
        data: {
          id: @checklist_column.repository_checklist_items.first.id,
          type: 'inventory_checklist_items',
          attributes: { data: 'Updated' }
        }
      }
    end

    it 'Response with correct inventory list item' do
      hash_body = nil
      item_id = @checklist_column.repository_checklist_items.first.id
      put api_v1_team_inventory_column_checklist_item_path(
        id: item_id,
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@checklist_column.repository_checklist_items.find(item_id),
                 serializer: Api::V1::InventoryChecklistItemSerializer)
            .to_json
        )['data']
      )
      expect(@checklist_column.repository_checklist_items.find(item_id).data).to match('Updated')
    end

    it 'When invalid request, incorrect type' do
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data][:type] = 'repository_rows'
      hash_body = nil
      put api_v1_team_inventory_column_checklist_item_path(
        id: @checklist_column.repository_checklist_items.first.id,
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, missing attributes values' do
      hash_body = nil
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data][:attributes].delete(:data)
      put api_v1_team_inventory_column_checklist_item_path(
        id: @checklist_column.repository_checklist_items.first.id,
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, non existing item' do
      hash_body = nil
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:id] = 999
      put api_v1_team_inventory_column_checklist_item_path(
        id: 999,
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'DELETE inventory_checklist_item, #destroy' do
    it 'Destroys inventory list item' do
      deleted_id = @checklist_column.repository_checklist_items.last.id
      delete api_v1_team_inventory_column_checklist_item_path(
        id: deleted_id,
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column.id
      ), headers: @valid_headers
      expect(response).to have_http_status(200)
      expect(RepositoryChecklistItem.where(id: deleted_id)).to_not exist
    end

    it 'Invalid request, non existing inventory list item' do
      delete api_v1_team_inventory_column_checklist_item_path(
        id: 1001,
        team_id: @teams.first.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
    end

    it 'When invalid request, incorrect repository' do
      deleted_id = @checklist_column.repository_checklist_items.last.id
      delete api_v1_team_inventory_column_checklist_item_path(
        id: deleted_id,
        team_id: @teams.first.id,
        inventory_id: 9999,
        column_id: @checklist_column.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect(RepositoryChecklistItem.where(id: deleted_id)).to exist
    end

    it 'When invalid request, repository from another team' do
      deleted_id = @checklist_column.repository_checklist_items.last.id
      delete api_v1_team_inventory_column_checklist_item_path(
        id: deleted_id,
        team_id: @teams.second.id,
        inventory_id: @valid_inventory.id,
        column_id: @checklist_column.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect(RepositoryChecklistItem.where(id: deleted_id)).to exist
    end
  end
end
