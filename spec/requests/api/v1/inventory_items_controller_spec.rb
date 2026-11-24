# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::InventoryItemsController', type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team1 = create(:team, :record_deletion_enabled, created_by: @user)
    @team2 = create(:team, :record_deletion_enabled, created_by: @another_user)

    # valid_inventory
    @valid_inventory = create(:repository, name: Faker::Name.unique.name,
                              created_by: @user, team: @team1)

    # unaccessable_inventory
    create(:repository, name: Faker::Name.unique.name,
                created_by: @another_user, team: @team2)

    @text_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryTextValue)
    list_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryListValue)
    list_item =
      create(:repository_list_item, repository_column: list_column, data: Faker::Name.unique.name)
    file_column = create(:repository_column, name: Faker::Name.unique.name,
      repository: @valid_inventory, data_type: :RepositoryAssetValue)
    asset = create(:asset)

    @repository_rows = create_list(:repository_row, 100, repository: @valid_inventory)

    @searchable_repository_row = @repository_rows.last

    @valid_inventory.repository_rows.each_with_index do |row, i|
      create(:repository_text_value,
             data: row.id == @searchable_repository_row.id ? 'SEARCH TEXT VALUE' : Faker::Name.name,
             repository_cell_attributes:
               { repository_row: row, repository_column: @text_column })
      create(:repository_list_value, repository_list_item: list_item,
             repository_cell_attributes:
               { repository_row: row, repository_column: list_column })
      create(:repository_asset_value, asset: asset,
             repository_cell_attributes:
               { repository_row: row, repository_column: file_column })
    end

    @child_inventory_item = create(:repository_row, repository: @valid_inventory, created_by: @user)
    @child_connection = create(:repository_row_connection, parent: @valid_inventory.repository_rows.first, child: @child_inventory_item, created_by: @user)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id),
        'Content-Type': 'application/json' }

    @valid_hash_body = { data:
                         { type: 'inventory_items',
                           attributes: {
                             name: Faker::Name.unique.name
                           } },
                         included: [
                           { type: 'inventory_cells',
                             attributes: {
                               column_id: @text_column.id,
                               value: Faker::Name.unique.name
                             } }
                         ] }
  end

  describe 'GET inventory_items, #index' do
    it 'Response with correct inventory items, default per page' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match_array(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_inventory.repository_rows.order(:id).limit(10),
                 each_serializer: Api::V1::InventoryItemSerializer,
                 include: :inventory_cells)
            .to_json
        )['data']
      )
      expect(hash_body).not_to include('included')
    end

    it 'Response with correct inventory items, included cells' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id,
        include: 'inventory_cells,parents,children'
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match_array(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_inventory.repository_rows.order(:id).limit(10),
                 each_serializer: Api::V1::InventoryItemSerializer,
                 include: :inventory_cells)
            .to_json
        )['data']
      )
      expect(hash_body[:included]).to match_array(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_inventory.repository_rows.order(:id).limit(10),
                 each_serializer: Api::V1::InventoryItemSerializer,
                 include: %w(inventory_cells parents children))
            .to_json
        )['included']
      )
    end

    it 'Response with correct inventory items, 100 per page' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), params: { page: { size: 100 } }, headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match_array(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_inventory.repository_rows.order(:id).limit(100),
                 each_serializer: Api::V1::InventoryItemSerializer)
            .to_json
        )['data']
      )
      expect(hash_body).not_to include('included')
    end

    it 'When provided a column filter, finds correct item' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), params: {
          filter: {
            inventory_column: {
              id: @text_column.id,
              value: {
                operator: 'contains',
                text: 'SEARCH TEXT VALUE'
              }
            }
          }
        }, headers: @valid_headers

      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data].length).to eq(1)
      expect(hash_body[:data].first[:id].to_i).to eq(@searchable_repository_row.id)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @team2.id,
        inventory_id: @team2.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @team1.id,
        inventory_id: 123
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      get api_v1_team_inventory_items_path(
        team_id: @team1.id,
        inventory_id: @team2.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    context 'when have some archived rows' do
      before do
        create(:repository_row, :archived,
               name: Faker::Name.unique.name, created_by: @user, repository: @team1.repositories.first)
      end

      it 'will ignore them' do
        hash_body = nil

        get api_v1_team_inventory_items_path(
          team_id: @team1.id,
          inventory_id: @team1.repositories.first.id
        ), params: { page: { size: 200 } }, headers: @valid_headers

        expect { hash_body = json }.not_to raise_exception
        expect(hash_body['data'].count).to be_eql 100
      end

      it 'return rows with archived filter true' do
        hash_body = nil

        get api_v1_team_inventory_items_path(
          team_id: @team1.id,
          inventory_id: @team1.repositories.first.id
        ), params: { filter: { archived: true }, page: { size: 200 } }, headers: @valid_headers

        expect { hash_body = json }.not_to raise_exception
        expect(hash_body['data'].count).to be_eql 1
      end

      it 'return rows with archived filter false' do
        hash_body = nil

        get api_v1_team_inventory_items_path(
          team_id: @team1.id,
          inventory_id: @team1.repositories.first.id
        ), params: { filter: { archived: false }, page: { size: 200 } }, headers: @valid_headers

        expect { hash_body = json }.not_to raise_exception
        expect(hash_body['data'].count).to be_eql 100
      end
    end
  end

  describe 'DELETE inventory_items, #destroy' do
    it 'Destroys inventory item' do
      row = @team1.repositories.first.repository_rows.last
      row.archive!(@user)
      deleted_id = row.id
      delete api_v1_team_inventory_item_path(
        id: deleted_id,
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(200)
      expect(RepositoryRow.where(id: deleted_id)).to_not exist
      expect(RepositoryCell.where(repository_row: deleted_id).count).to equal 0
    end

    it 'Invalid request, non existing inventory item' do
      deleted_id = RepositoryRow.last.id + 1
      delete api_v1_team_inventory_item_path(
        id: deleted_id,
        team_id: @team1.id,
        inventory_id: @team1.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
    end

    it 'When invalid request, incorrect repository' do
      deleted_id = @team1.repositories.first.repository_rows.last.id
      delete api_v1_team_inventory_item_path(
        id: deleted_id,
        team_id: @team1.id,
        inventory_id: @team2.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect(RepositoryRow.where(id: deleted_id)).to exist
    end

    it 'When invalid request, repository from another team' do
      deleted_id = @team1.repositories.first.repository_rows.last.id
      delete api_v1_team_inventory_item_path(
        id: deleted_id,
        team_id: @team2.id,
        inventory_id: @team1.repositories.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect(RepositoryRow.where(id: deleted_id)).to exist
    end
  end

  describe 'POST inventory_item, #create' do
    it 'Response with correct inventory item' do
      hash_body = nil
      post api_v1_team_inventory_items_path(
        team_id: @team1.id,
        inventory_id: @valid_inventory.id
      ), params: @valid_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryRow.last, serializer: Api::V1::InventoryItemSerializer, include: :inventory_cells)
            .to_json
        )['data']
      )
      expect(hash_body[:included]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(RepositoryRow.last, serializer: Api::V1::InventoryItemSerializer, include: :inventory_cells)
            .to_json
        )['included']
      )
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      post api_v1_team_inventory_items_path(
        team_id: @team1.id,
        inventory_id: -1
      ), params: @valid_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      post api_v1_team_inventory_items_path(
        team_id: @team2.id,
        inventory_id: @valid_inventory.id
      ), params: @valid_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      post api_v1_team_inventory_items_path(
        team_id: @team1.id,
        inventory_id: @team2.repositories.first.id
      ), params: @valid_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
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
      updated_inventory_item = JSON.parse(@inventory_item.to_json)['data']
      updated_inventory_item['attributes']['name'] = Faker::Name.unique.name
      patch api_v1_team_inventory_item_path(
        id: RepositoryRow.last.id,
        team_id: @team1.id,
        inventory_id: @valid_inventory.id
      ), params: { data: updated_inventory_item }.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['data']['attributes']['name']).to match(updated_inventory_item['attributes']['name'])
    end
  end

  describe 'POST inventory_item, #create with mandatory columns' do
    let(:headers) do
      { 'Authorization' => "Bearer #{generate_token(@user.id)}", 'Content-Type' => 'application/json' }
    end
    let!(:inventory) { create(:repository, created_by: @user, team: @team1) }
    let!(:mandatory_column) do
      create(:repository_column, repository: inventory, created_by: @user,
                                 data_type: :RepositoryTextValue, mandatory: true)
    end
    let!(:optional_column) do
      create(:repository_column, repository: inventory, created_by: @user, data_type: :RepositoryTextValue)
    end

    def create_item(cells)
      body = { data: { type: 'inventory_items', attributes: { name: 'API item' } } }
      if cells.any?
        body[:included] = cells.map do |column, value|
          { type: 'inventory_cells', attributes: { column_id: column.id, value: value } }
        end
      end
      post api_v1_team_inventory_items_path(team_id: @team1.id, inventory_id: inventory.id),
           params: body.to_json, headers: headers
    end

    def mandatory_detail(column)
      I18n.t('api.core.errors.inventory_column_mandatory.detail', column_name: column.name, id: column.id)
    end

    def inventory_item_count
      RepositoryRow.where(repository: inventory).count
    end

    it 'rejects an item without cells and names the missing mandatory column' do
      expect { create_item({}) }.not_to(change { inventory_item_count })

      expect(response).to have_http_status(400)
      expect(json['errors'].size).to eq 1
      expect(json['errors'][0]).to include(
        'status' => 400,
        'title' => I18n.t('api.core.errors.inventory_column_mandatory.title'),
        'detail' => mandatory_detail(mandatory_column)
      )
    end

    it 'rejects an item whose cells skip mandatory columns, with one error per missing column' do
      second_mandatory_column = create(:repository_column, repository: inventory, created_by: @user,
                                                           data_type: :RepositoryTextValue, mandatory: true)

      expect { create_item(optional_column => 'optional value') }.not_to(change { inventory_item_count })

      expect(response).to have_http_status(400)
      expect(json['errors'].pluck('detail')).to contain_exactly(
        mandatory_detail(mandatory_column), mandatory_detail(second_mandatory_column)
      )
    end

    it 'creates the item when every mandatory column has a value' do
      expect { create_item(mandatory_column => 'required value') }.to change { inventory_item_count }.by(1)

      expect(response).to have_http_status(201)
      item = RepositoryRow.find(json['data']['id'])
      expect(item.repository_cells.find_by(repository_column: mandatory_column).value.data).to eq 'required value'
    end

    it 'creates an item without cells when the inventory has no mandatory columns' do
      mandatory_column.update!(mandatory: false)

      expect { create_item({}) }.to change { inventory_item_count }.by(1)
      expect(response).to have_http_status(201)
    end

    it 'skips the mandatory check when inventory integrity is disabled' do
      allow(RepositoryBase).to receive(:inventory_integrity_enabled?).and_return(false)

      expect { create_item({}) }.to change { inventory_item_count }.by(1)
      expect(response).to have_http_status(201)
    end
  end

  describe 'inventory item uniqueness' do
    let(:headers) do
      { 'Authorization' => "Bearer #{generate_token(@user.id)}", 'Content-Type' => 'application/json' }
    end
    let!(:inventory) { create(:repository, created_by: @user, team: @team1, enforce_unique_item_names: true) }
    let!(:unique_column) do
      create(:repository_column, repository: inventory, created_by: @user, data_type: :RepositoryTextValue,
                                 enforce_unique: true, unique_case_sensitive: true)
    end
    let!(:existing_item) { create(:repository_row, repository: inventory, created_by: @user, name: 'Sample A') }
    let!(:existing_value) do
      create(:repository_text_value, data: 'LOT-1', created_by: @user,
                                     repository_cell_attributes: { repository_row: existing_item,
                                                                   repository_column: unique_column })
    end

    def inventory_item_count
      RepositoryRow.where(repository: inventory).count
    end

    def post_item(body)
      post api_v1_team_inventory_items_path(team_id: @team1.id, inventory_id: inventory.id),
           params: body.to_json, headers: headers
    end

    it 'rejects a new item with a duplicate value in a unique Text column' do
      body = { data: { type: 'inventory_items', attributes: { name: 'Sample B' } },
               included: [{ type: 'inventory_cells', attributes: { column_id: unique_column.id, value: 'LOT-1' } }] }

      expect { post_item(body) }.not_to(change { inventory_item_count })

      expect(response).to have_http_status(400)
      expect(json['errors'][0]['title']).to eq I18n.t('api.core.errors.validation.title')
      expect(json['errors'][0]['detail'])
        .to include(I18n.t('activerecord.errors.models.repository_text_value.attributes.data.not_unique'))
    end

    it 'accepts a duplicate name and value when inventory integrity is disabled' do
      allow(RepositoryBase).to receive(:inventory_integrity_enabled?).and_return(false)
      body = { data: { type: 'inventory_items', attributes: { name: 'Sample A' } },
               included: [{ type: 'inventory_cells', attributes: { column_id: unique_column.id, value: 'LOT-1' } }] }

      expect { post_item(body) }.to change { inventory_item_count }.by(1)
      expect(response).to have_http_status(201)
    end

    it 'rejects a new item with a duplicate name' do
      body = { data: { type: 'inventory_items', attributes: { name: 'Sample A' } } }

      expect { post_item(body) }.not_to(change { inventory_item_count })

      expect(response).to have_http_status(400)
      expect(json['errors'][0]['detail'])
        .to include(I18n.t('activerecord.errors.models.repository_row.attributes.name.not_unique'))
    end

    it 'rejects updating a cell to a duplicate value and keeps the old value' do
      other_item = create(:repository_row, repository: inventory, created_by: @user, name: 'Sample B')
      other_value = create(:repository_text_value, data: 'LOT-2', created_by: @user,
                                                   repository_cell_attributes: { repository_row: other_item,
                                                                                 repository_column: unique_column })
      body = { data: { id: other_item.id, type: 'inventory_items', attributes: { name: other_item.name } },
               included: [{ id: other_value.repository_cell.id, type: 'inventory_cells',
                            attributes: { value: 'LOT-1' } }] }

      patch api_v1_team_inventory_item_path(team_id: @team1.id, inventory_id: inventory.id, id: other_item.id),
            params: body.to_json, headers: headers

      expect(response).to have_http_status(400)
      expect(json['errors'][0]['detail'])
        .to include(I18n.t('activerecord.errors.models.repository_text_value.attributes.data.not_unique'))
      expect(other_value.reload.data).to eq 'LOT-2'
    end

    it 'returns 204 without a body when the update changes nothing' do
      body = { data: { id: existing_item.id, type: 'inventory_items', attributes: { name: existing_item.name } } }

      patch api_v1_team_inventory_item_path(team_id: @team1.id, inventory_id: inventory.id, id: existing_item.id),
            params: body.to_json, headers: headers

      expect(response).to have_http_status(204)
      expect(response.body).to be_empty
    end
  end
end
