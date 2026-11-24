# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::InventoriesController', type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team1 = create(:team, :record_deletion_enabled, created_by: @user)
    @team2 = create(:team, :record_deletion_enabled, created_by: @another_user)

    # valid_inventories
    create(:repository, name: Faker::Name.unique.name,
            created_by: @user, team: @team1)
    create(:repository, name: Faker::Name.unique.name,
            created_by: @user, team: @team1)

    # unaccessable_inventories
    create(:repository, name: Faker::Name.unique.name,
                created_by: @another_user, team: @team2)
    create(:repository, name: Faker::Name.unique.name,
                created_by: @another_user, team: @team2)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET inventories, #index' do
    it 'Response with correct inventories' do
      hash_body = nil
      get api_v1_team_inventories_path(team_id: @team1.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@team1.repositories, each_serializer: Api::V1::InventorySerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventories_path(team_id: @team2.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    context 'when have some archived inventories' do
      before do
        create(:repository, :archived, name: Faker::Name.unique.name, created_by: @user, team: @team1)
      end

      it 'will ignore them' do
        hash_body = nil

        get api_v1_team_inventories_path(team_id: @team1.id), headers: @valid_headers

        expect { hash_body = json }.not_to raise_exception
        expect(hash_body['data'].count).to be_eql 2
      end
    end
  end

  describe 'GET inventory, #show' do
    it 'When valid request, user is member of the team' do
      hash_body = nil
      get api_v1_team_inventory_path(team_id: @team1.id,
                                id: @team1.repositories.first.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception

      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@team1.repositories.first, serializer: Api::V1::InventorySerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_inventory_path(team_id: @team2.id,
                                id: @team2.repositories.first.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing inventory' do
      hash_body = nil
      get api_v1_team_inventory_path(team_id: @team1.id, id: -1),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, repository from another team' do
      hash_body = nil
      get api_v1_team_inventory_path(team_id: @team1.id,
                                id: @team2.repositories.first.id),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST inventory, #create' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @request_body = { data:
                         { type: 'inventories',
                           attributes: {
                             name: Faker::Name.unique.name
                           } } }
    end

    it 'Response with correct inventory' do
      hash_body = nil
      post api_v1_team_inventories_path(
        team_id: @team1.id
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource.new(Repository.last, serializer: Api::V1::InventorySerializer)
          .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      post api_v1_team_inventories_path(
        team_id: @team2.id
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 403
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non-existent team' do
      hash_body = nil
      post api_v1_team_inventories_path(
        team_id: -1
      ), params: @request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 404
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, incorrect type' do
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data][:type] = 'repository_rows'
      hash_body = nil
      post api_v1_team_inventories_path(
        team_id: @team1.id
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, missing data param' do
      hash_body = nil
      post api_v1_team_inventories_path(
        team_id: @team1.id
      ), params: {}, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, missing attributes param' do
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data].delete(:attributes)
      hash_body = nil
      post api_v1_team_inventories_path(
        team_id: @team1.id
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end

    it 'When invalid request, missing type param' do
      invalid_request_body = @request_body.deep_dup
      invalid_request_body[:data].delete(:type)
      hash_body = nil
      post api_v1_team_inventories_path(
        team_id: @team1.id
      ), params: invalid_request_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(400)
      expect { hash_body = json }.to_not raise_exception
      expect(hash_body['errors'][0]).to include('status': 400)
    end
  end

  describe 'PATCH inventory, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @inventory = ActiveModelSerializers::SerializableResource.new(
        Repository.first,
        serializer: Api::V1::InventorySerializer
      )
    end

    it 'Response with correctly updated inventory' do
      hash_body = nil
      updated_inventory = @inventory.as_json
      updated_inventory[:data][:attributes][:name] =
        Faker::Name.unique.name
      patch api_v1_team_inventory_path(
        id: updated_inventory[:data][:id],
        team_id: @team1.id
      ), params: updated_inventory.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['data']['attributes']['name']).to match(updated_inventory[:data][:attributes][:name])
    end

    it 'When invalid request, inventory does not belong to team' do
      hash_body = nil
      updated_inventory = @inventory.as_json
      updated_inventory[:data][:attributes][:name] =
        Faker::Name.unique.name
      patch api_v1_team_inventory_path(
        id: @team2.repositories.first.id,
        team_id: @team1.id
      ), params: updated_inventory.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 404
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, non-existent inventory' do
      hash_body = nil
      updated_inventory = @inventory.as_json
      updated_inventory[:data][:attributes][:name] =
        Faker::Name.unique.name
      patch api_v1_team_inventory_path(
        id: -1,
        team_id: @team1.id
      ), params: updated_inventory.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 404
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      updated_inventory = @inventory.as_json
      updated_inventory[:data][:attributes][:name] =
        Faker::Name.unique.name
      patch api_v1_team_inventory_path(
        id: @team2.repositories.first.id,
        team_id: @team2.id
      ), params: updated_inventory.to_json,
      headers: @valid_headers
      expect(response).to have_http_status 403
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end
  end

  describe 'DELETE inventories, #destroy' do
    it 'Destroys inventory' do
      deleted_id = @team1.repositories.last.id
      @team1.repositories.last.archive!(@user)
      delete api_v1_team_inventory_path(
        id: deleted_id,
        team_id: @team1.id
      ), headers: @valid_headers
      expect(response).to have_http_status(200)
      expect(Repository.where(id: deleted_id)).to_not exist
      expect(RepositoryRow.where(repository: deleted_id).count).to equal 0
      expect(RepositoryColumn.where(repository: deleted_id).count).to equal 0
    end

    it 'Invalid request, non existing inventory' do
      delete api_v1_team_inventory_path(
        id: -1,
        team_id: @team1.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
    end

    it 'When invalid request, repository from another team' do
      deleted_id = @team1.repositories.last.id
      delete api_v1_team_inventory_path(
        id: deleted_id,
        team_id: @team2.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect(Repository.where(id: deleted_id)).to exist
    end
  end

  describe 'item name uniqueness settings' do
    let(:headers) do
      { 'Authorization' => "Bearer #{generate_token(@user.id)}", 'Content-Type' => 'application/json' }
    end
    let!(:inventory) do
      create(:repository, created_by: @user, team: @team1,
                          enforce_unique_item_names: true, unique_item_names_case_sensitive: false)
    end

    def show_inventory_attributes
      get api_v1_team_inventory_path(team_id: @team1.id, id: inventory.id), headers: headers
      json['data']['attributes']
    end

    def patch_inventory(attributes)
      patch api_v1_team_inventory_path(team_id: @team1.id, id: inventory.id),
            params: { data: { id: inventory.id, type: 'inventories', attributes: attributes } }.to_json,
            headers: headers
    end

    it 'shows the item name uniqueness settings' do
      expect(show_inventory_attributes)
        .to include('enforce_unique_item_names' => true, 'unique_item_names_case_sensitive' => false)
    end

    it 'updates the item name uniqueness settings' do
      patch_inventory(enforce_unique_item_names: false, unique_item_names_case_sensitive: true)

      expect(response).to have_http_status(200)
      expect(json['data']['attributes'])
        .to include('enforce_unique_item_names' => false, 'unique_item_names_case_sensitive' => true)
      expect(inventory.reload)
        .to have_attributes(enforce_unique_item_names: false, unique_item_names_case_sensitive: true)
    end

    it 'creates an inventory with item name uniqueness enabled' do
      post api_v1_team_inventories_path(team_id: @team1.id),
           params: { data: { type: 'inventories',
                             attributes: { name: 'Unique names inventory', enforce_unique_item_names: true } } }.to_json,
           headers: headers

      expect(response).to have_http_status(201)
      expect(Repository.find(json['data']['id']).enforce_unique_item_names).to be true
    end

    it 'returns 204 without a body when the update changes nothing' do
      patch_inventory(name: inventory.name)

      expect(response).to have_http_status(204)
      expect(response.body).to be_empty
    end

    context 'when inventory integrity is disabled' do
      before { allow(RepositoryBase).to receive(:inventory_integrity_enabled?).and_return(false) }

      it 'hides the item name uniqueness settings' do
        attributes = show_inventory_attributes

        expect(attributes).not_to have_key('enforce_unique_item_names')
        expect(attributes).not_to have_key('unique_item_names_case_sensitive')
      end

      it 'ignores item name uniqueness settings in an update' do
        patch_inventory(enforce_unique_item_names: false, unique_item_names_case_sensitive: true)

        expect(response).to have_http_status(204)
        expect(inventory.reload)
          .to have_attributes(enforce_unique_item_names: true, unique_item_names_case_sensitive: false)
      end

      it 'ignores item name uniqueness settings on create' do
        post api_v1_team_inventories_path(team_id: @team1.id),
             params: { data: { type: 'inventories',
                               attributes: { name: 'Flag off inventory', enforce_unique_item_names: true } } }.to_json,
             headers: headers

        expect(response).to have_http_status(201)
        expect(Repository.find(json['data']['id']).enforce_unique_item_names).to be false
      end
    end
  end
end
