# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::InventoryColumnsController', type: :request do
  before :all do
    ApplicationSettings.instance.update(
      values: ApplicationSettings.instance.values.merge({"stock_management_enabled" => true})
    )

    @user = create(:user)
    @another_user = create(:user)
    @team1 = create(:team, created_by: @user)
    @team2 = create(:team, created_by: @another_user)

    # valid_inventory
    @valid_inventory = create(:repository, name: Faker::Name.unique.name,
                              created_by: @user, team: @team1)
    # valid_stock inventory
    @valid_stock_inventory = create(:repository, name: Faker::Name.unique.name,
      created_by: @user, team: @team1)

    # unaccessable_inventory
    create(:repository, name: Faker::Name.unique.name,
                created_by: @another_user, team: @team2)

    @stock_column = create(:repository_column, name: Faker::Name.unique.name,
                          data_type: :RepositoryStockValue, repository: @valid_stock_inventory)
    create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryTextValue)
    @list_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryListValue)
    create(:repository_list_item, repository_column: @list_column, data: Faker::Name.unique.name)
    @status_column = create(:repository_column, name: Faker::Name.unique.name,
                         repository: @valid_inventory, data_type: :RepositoryStatusValue)
    create(:repository_status_item, repository_column: @status_column, status: Faker::Name.unique.name, icon: 'icon')
    create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryAssetValue)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET inventory_columns, #index' do
    it 'Response with correct inventory items, default per page' do
      hash_body = nil
      get api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_inventory.repository_columns.limit(10),
                 each_serializer: Api::V1::InventoryColumnSerializer,
                 hide_list_items: true)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_columns_path(
        team_id: @team2.id,
        inventory_id: @team2.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      get api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: 123
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      get api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: @team2.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET inventory_column, #show' do
    it 'Valid text column response' do
      text_column = @valid_inventory.repository_columns.first
      hash_body = nil
      get api_v1_team_inventory_column_path(
        id: text_column.id,
        team_id: @team1.id,
        inventory_id: @valid_inventory.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(text_column, serializer: Api::V1::InventoryColumnSerializer)
            .to_json
        )['data']
      )
      expect(hash_body[:data]).not_to include('relationships')
    end

    it 'Valid list column response' do
      hash_body = nil
      get api_v1_team_inventory_column_path(
        id: @list_column.id,
        team_id: @team1.id,
        inventory_id: @valid_inventory.id,
        include: 'inventory_list_items'
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@list_column, serializer: Api::V1::InventoryColumnSerializer)
            .to_json
        )['data']
      )
      expect(hash_body[:data]).to include('relationships')
      expect(hash_body[:included]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_inventory.repository_columns.limit(10),
                 each_serializer: Api::V1::InventoryColumnSerializer,
                 include: :inventory_list_items)
            .to_json
        )['included']
      )
    end

    it 'Valid status column response' do
      hash_body = nil
      get api_v1_team_inventory_column_path(
        id: @status_column.id,
        team_id: @team1.id,
        inventory_id: @valid_inventory.id,
        include: 'inventory_status_items'
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@status_column, serializer: Api::V1::InventoryColumnSerializer)
            .to_json
        )['data']
      )
      expect(hash_body[:data]).to include('relationships')
      expect(hash_body[:included]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_inventory.repository_columns.limit(10),
                 each_serializer: Api::V1::InventoryColumnSerializer,
                 include: :inventory_status_items)
            .to_json
        )['included']
      )
    end

    it 'Valid file column response' do
      file_column = @valid_inventory.repository_columns.asset_type.first
      hash_body = nil
      get api_v1_team_inventory_column_path(
        id: file_column.id,
        team_id: @team1.id,
        inventory_id: @valid_inventory.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(file_column, serializer: Api::V1::InventoryColumnSerializer)
            .to_json
        )['data']
      )
      expect(hash_body[:data]).not_to include('relationships')
    end

    it 'Invalid request, non existing inventory column' do
      get api_v1_team_inventory_column_path(
        id: 1001,
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
    end

    it 'When invalid request, incorrect repository' do
      id = @team1.repositories.first.repository_columns.last.id
      get api_v1_team_inventory_column_path(
        id: id,
        team_id: @team1.id,
        inventory_id: @team2.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect(RepositoryColumn.where(id: id)).to exist
    end

    it 'When invalid request, repository from another team' do
      id = @team1.repositories.first.repository_columns.last.id
      get api_v1_team_inventory_column_path(
        id: id,
        team_id: @team2.id,
        inventory_id: @team1.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect(RepositoryColumn.where(id: id)).to exist
    end
  end

  describe 'POST inventory_column, #create' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @request_body = { data:
                         { type: 'inventory_columns',
                           attributes: {
                             name: Faker::Name.unique.name,
                             data_type: 'text'
                           } } }
    end

    let!(:request_body_stock) {{ data:
      { type: 'inventory_columns',
        attributes: {
          name: Faker::Name.unique.name,
          data_type: 'stock',
          metadata: {
             decimals: 3
          }
        } } }}

    it 'Response with correct inventory column' do
      hash_body = nil
      post api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryColumn.last, serializer: Api::V1::InventoryColumnSerializer, include: :inventory_cells)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      post api_v1_team_inventory_columns_path(
        team_id: @team2.id,
        inventory_id: @team1.repositories.first.id
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 403
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      post api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: 123
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 404
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      post api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: @team2.repositories.first.id
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, incorrect type' do
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data][:type] = 'repository_rows'
      hash_body = nil
      post api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, missing data param' do
      hash_body = nil
      post api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), params: {}, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, missing attributes param' do
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data].delete(:attributes)
      hash_body = nil
      post api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, missing type param' do
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data].delete(:type)
      hash_body = nil
      post api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, missing attributes values' do
      hash_body = nil
      %i(name data_type).each do |attr|
        invalid_request_body = @request_body.deep_dup
        invalid_request_body[:data][:attributes].delete(attr)
        post api_v1_team_inventory_columns_path(
          team_id: @team1.id,
          inventory_id: @team1.repositories.first.id
        ), params: invalid_request_body.to_json, headers: @valid_headers
        expect(response).to have_http_status(400)
        expect { hash_body = json }.to_not raise_exception
        expect(hash_body['errors'][0]).to include('status': 400)
      end
    end

    it 'Response with correct stock inventory column' do
      hash_body = nil
      post api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), params: request_body_stock.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryColumn.last, serializer: Api::V1::InventoryColumnSerializer, hide_list_items: true)
            .to_json
        )['data']
      )
    end

    it 'Raised error with already exsisting stock column in column' do
      hash_body = nil
      post api_v1_team_inventory_columns_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.second.id
      ), params: request_body_stock.to_json, headers: @valid_headers
      expect(response).to have_http_status 400
    end
  end

  describe 'DELETE inventory_columns, #destroy' do
    it 'Destroys inventory column' do
      deleted_id = @team1.repositories.first.repository_columns.last.id
      delete api_v1_team_inventory_column_path(
        id: deleted_id,
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(200)
      expect(RepositoryColumn.where(id: deleted_id)).to_not exist
      expect(RepositoryCell.where(repository_column: deleted_id).count).to equal 0
    end

    it 'Invalid request, non existing inventory column' do
      delete api_v1_team_inventory_column_path(
        id: 1001,
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
    end

    it 'When invalid request, incorrect repository' do
      deleted_id = @team1.repositories.first.repository_columns.last.id
      delete api_v1_team_inventory_column_path(
        id: deleted_id,
        team_id: @team1.id,
        inventory_id: @team2.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect(RepositoryColumn.where(id: deleted_id)).to exist
    end

    it 'When invalid request, repository from another team' do
      deleted_id = @team1.repositories.first.repository_columns.last.id
      delete api_v1_team_inventory_column_path(
        id: deleted_id,
        team_id: @team2.id,
        inventory_id: @team1.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect(RepositoryColumn.where(id: deleted_id)).to exist
    end

    it 'Destroy Stock inventory column' do
      deleted_id = @team1.repositories.second.repository_columns.last.id
      delete api_v1_team_inventory_column_path(
        id: deleted_id,
        team_id: @team1.id,
        inventory_id: @team1.repositories.second.id
      ), headers: @valid_headers
      expect(response).to have_http_status(200)
      expect(RepositoryColumn.where(id: deleted_id)).to_not exist
      expect(RepositoryCell.where(repository_column: deleted_id).count).to equal 0
    end
  end

  describe 'PATCH inventory_column, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @inventory_column = ActiveModelSerializers::SerializableResource.new(
        RepositoryColumn.last,
        serializer: Api::V1::InventoryColumnSerializer
      )
    end

    let!(:request_body_stock_update) {
      ActiveModelSerializers::SerializableResource.new(
        @team1.repositories.second.repository_columns.last,
        serializer: Api::V1::InventoryColumnSerializer
      )

    }

    it 'Response with correctly updated inventory column' do
      hash_body = nil
      updated_inventory_column = @inventory_column.as_json
      updated_inventory_column[:data][:attributes][:name] =
        Faker::Name.unique.name
      returned_inventory_column = updated_inventory_column.deep_dup
      updated_inventory_column[:data][:attributes].delete(:data_type)
      patch api_v1_team_inventory_column_path(
        id: RepositoryColumn.last.id,
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), params: updated_inventory_column.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['data']['attributes']['name']).to match(returned_inventory_column[:data][:attributes][:name])
    end

    it 'Response with correctly updated inventory stock column' do
      hash_body = nil
      updated_inventory_column = request_body_stock_update.as_json
      updated_inventory_column[:data][:attributes][:metadata][:decimals] = 0
      returned_inventory_column = updated_inventory_column.deep_dup
      updated_inventory_column[:data][:attributes].delete(:data_type)
      patch api_v1_team_inventory_column_path(
        id: @team1.repositories.second.repository_columns.last.id,
        team_id: @team1.id,
        inventory_id: @team1.repositories.second.id
      ), params: updated_inventory_column.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['data']['attributes']['metadata']['decimals']).to match(returned_inventory_column[:data][:attributes][:metadata][:decimals])
    end

    it 'Invalid request, wrong team' do
      hash_body = nil
      updated_inventory_column = @inventory_column.as_json
      updated_inventory_column[:data][:attributes][:name] =
        Faker::Name.unique.name
      patch api_v1_team_inventory_column_path(
        id: RepositoryColumn.last.id,
        team_id: @team2.id,
        inventory_id: @team1.repositories.first.id
      ), params: updated_inventory_column.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 403
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'Invalid request, wrong inventory' do
      hash_body = nil
      updated_inventory_column = @inventory_column.as_json
      updated_inventory_column[:data][:attributes][:name] =
        Faker::Name.unique.name
      patch api_v1_team_inventory_column_path(
        id: RepositoryColumn.last.id,
        team_id: @team2.id,
        inventory_id: @team2.repositories.first.id
      ), params: updated_inventory_column.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 403
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'Invalid request, non-existent inventory' do
      hash_body = nil
      updated_inventory_column = @inventory_column.as_json
      updated_inventory_column[:data][:attributes][:name] =
        Faker::Name.unique.name
      patch api_v1_team_inventory_column_path(
        id: RepositoryColumn.last.id,
        team_id: @team1.id,
        inventory_id: 123
      ), params: updated_inventory_column.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 404
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end
end
