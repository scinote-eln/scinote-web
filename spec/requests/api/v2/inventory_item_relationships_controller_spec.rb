require 'rails_helper'

RSpec.describe 'Api::V2::InventoryItemRelationshipsController', type: :request do
  before :all do
    @user = create(:user)
    @normal_user = create(:user, full_name: 'Normal User')
    @team = create(:team, created_by: @user)
    @inventory = create(:repository, team: @team, created_by: @user)
    @other_inventory = create(:repository, team: @team, created_by: @user)
    @inventory_item = create(:repository_row, repository: @inventory, created_by: @user)
    @other_inventory_item = create(:repository_row, repository: @other_inventory, created_by: @user)

    @valid_headers = {
                        'Authorization': 'Bearer ' + generate_token(@user.id),
                        'Content-Type': 'application/json'
                      }
  end

  describe 'POST #create' do
    let(:create_action) do
      post api_v2_team_inventory_item_inventory_item_relationships_path(
        team_id: @team.id,
        inventory_id: @inventory.id,
        item_id: @inventory_item.id
      ), params: request_body.to_json, headers: @valid_headers
    end

    context 'with valid parameters' do
      context 'using parent_id' do
        let(:request_body) do
          {
            data: {
              type: 'inventory_item_relationships',
              attributes: {
                parent_id: @other_inventory_item.id
              }
            }
          }
        end
  
        it 'creates a new relationship' do
          expect { create_action }.to change { RepositoryRowConnection.count }.by(1)
          expect(response).to have_http_status(201)
        end
      end

      context 'using child_id' do
        let(:request_body) do
          {
            data: {
              type: 'inventory_item_relationships',
              attributes: {
                parent_id: @other_inventory_item.id
              }
            }
          }
        end
  
        it 'creates a new relationship' do
          expect { create_action }.to change { RepositoryRowConnection.count }.by(1)
          expect(response).to have_http_status(201)
        end
      end
    end

    context 'with non valid parameters' do
      context 'with mutually exclusive parameters' do
        let(:request_body) do
          {
            data: {
              type: 'inventory_item_relationships',
              attributes: {
                parent_id: @inventory_item.id,
                child_id: @other_inventory_item.id
              }
            }
          }
        end
  
        it 'raises a mutually exclusive parameters error' do
          create_action
          expect(response).to have_http_status(400)
        end
      end
  
      context 'with missing type' do
        let(:request_body) { { data: { type: '', attributes: { parent_id: @other_inventory_item.id } } } }
  
        it 'renders 400 bad request' do
          create_action
          expect(response).to have_http_status(400)
        end
      end
  
      context 'with missing item with parent_id or child_id' do
        let(:request_body) do
          {
            data: {
              type: 'inventory_item_relationships',
              attributes: {
                parent_id: -1
              }
            }
          }
        end
  
        it 'renders 404 not found' do
          create_action
          expect(response).to have_http_status(404)
        end
      end

      context 'without manage permission' do
        let(:another_create_action) do
          post api_v2_team_inventory_item_inventory_item_relationships_path(
            team_id: @team.id,
            inventory_id: @inventory.id,
            item_id: @inventory_item.id
          ),
          params: {
            data: {
              type: 'inventory_item_relationships',
              attributes: {
                parent_id: @other_inventory_item.id
              }
            }
          }.to_json,
          headers: {
            'Authorization': 'Bearer ' + generate_token(@normal_user.id),
            'Content-Type': 'application/json'
          }
        end

        it 'renders 403 forbidden' do
          another_create_action
          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:relationship) { create(:repository_row_connection, parent: @inventory_item, child: @other_inventory_item, created_by: @user) }

    let(:destroy_action) do
      delete api_v2_team_inventory_item_inventory_item_relationship_path(
        team_id: @team.id,
        inventory_id: @inventory.id,
        item_id: @inventory_item.id,
        id: relationship.id
      ), headers: @valid_headers
    end

    context 'with valid ID' do
      it 'deletes the relationship' do
        destroy_action
        expect(response).to have_http_status(200)
        expect(RepositoryRowConnection.where(id: relationship.id)).to_not exist
      end
    end

    context 'without manage permission' do
      let(:another_destroy_action) do
        delete api_v2_team_inventory_item_inventory_item_relationship_path(
          team_id: @team.id,
          inventory_id: @inventory.id,
          item_id: @inventory_item.id,
          id: relationship.id
        ),
        headers: {
          'Authorization': 'Bearer ' + generate_token(@normal_user.id),
          'Content-Type': 'application/json'
        }
      end

      it 'renders 403 forbidden' do
        another_destroy_action
        expect(response).to have_http_status(403)
        expect(RepositoryRowConnection.where(id: relationship.id)).to exist
      end
    end

    context 'with invalid ID' do
      it 'returns 404 not found' do
        delete api_v2_team_inventory_item_inventory_item_relationship_path(
          team_id: @team.id,
          inventory_id: @inventory.id,
          item_id: @inventory_item.id,
          id: -1
        ), headers: @valid_headers

        expect(response).to have_http_status(404)
      end
    end
  end
end
