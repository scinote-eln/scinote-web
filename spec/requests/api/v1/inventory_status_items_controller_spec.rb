# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::InventoryStatusItemsController', type: :request do
  before :all do
    @user = create(:user)
    @team1 = create(:team, created_by: @user)
    @team2 = create(:team, created_by: @user)
    @user_team = create(:user_team, :admin, user: @user, team: @team1)
    @inventory = create(:repository, name: Faker::Name.unique.name, created_by: @user, team: @team1)
    @wrong_inventory = create(:repository, name: Faker::Name.unique.name, created_by: @user, team: @team2)
    @status_column = create(:repository_column, name: Faker::Name.unique.name, repository: @inventory,
                            data_type: :RepositoryStatusValue)
    create_list(:repository_status_item, 10, repository: @inventory, repository_column: @status_column)
    @list_column = create(:repository_column, name: Faker::Name.unique.name,
                          repository: @inventory, data_type: :RepositoryListValue)
    @wrong_column = create(:repository_column, name: Faker::Name.unique.name, repository: @wrong_inventory,
                           data_type: :RepositoryStatusValue)
    @wrong_status_item = create(:repository_status_item, repository: @wrong_inventory, repository_column: @wrong_column)
    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET status_items, #index' do
    let(:team) { @team1 }
    let(:inventory) { @inventory }
    let(:column) { @status_column }
    let(:status_item) { @status_column.repository_status_items.first }
    let(:action) do
      get(api_v1_team_inventory_column_status_items_path(
            team_id: team.id,
            inventory_id: inventory.id,
            column_id: column.id
          ), headers: @valid_headers)
    end

    context 'when has valid params' do
      it 'renders 200' do
        action

        expect(response).to have_http_status(200)
      end

      it 'matchs expected response' do
        action

        expect(response).to match_json_schema('status_items/collection')
      end
    end

    context 'when user is not part of the team' do
      let(:team) { @team2 }

      it 'renders 403' do
        action

        expect(response).to have_http_status(403)
      end
    end

    context 'when there is no inventory' do
      let(:inventory) { @wrong_inventory }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when there is no column' do
      let(:column) { @wrong_column }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when column_type is wrong' do
      let(:column) { @list_column }

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end
  end

  describe 'GET status_item, #show' do
    let(:team) { @team1 }
    let(:inventory) { @inventory }
    let(:column) { @status_column }
    let(:status_item) { @status_column.repository_status_items.first }
    let(:action) do
      get(api_v1_team_inventory_column_status_item_path(
            team_id: team.id,
            inventory_id: inventory.id,
            column_id: column.id,
            id: status_item.id
          ), headers: @valid_headers)
    end

    context 'when has valid params' do
      it 'renders 200' do
        action

        expect(response).to have_http_status(200)
      end

      it 'matchs expected response' do
        action

        expect(response).to match_json_schema('status_items/resource')
      end
    end

    context 'when status_item does not extists' do
      let(:status_item) { @wrong_status_item }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when user is not part of the team' do
      let(:team) { @team2 }

      it 'renders 403' do
        action

        expect(response).to have_http_status(403)
      end
    end

    context 'when there is no inventory' do
      let(:inventory) { @wrong_inventory }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when there is no column' do
      let(:column) { @wrong_column }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when column_type is wrong' do
      let(:column) { @list_column }

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end
  end

  describe 'POST status_items, #create' do
    let(:team) { @team1 }
    let(:inventory) { @inventory }
    let(:column) { @status_column }
    let(:attributes) do
      {
        data: {
          type: 'inventory_status_items',
          attributes: {
            status: 'status',
            icon: 'icon'
          }
        }
      }
    end
    let(:action) do
      post(api_v1_team_inventory_column_status_items_path(
             team_id: team.id,
             inventory_id: inventory.id,
             column_id: column.id
           ), params: attributes, headers: @valid_headers)
    end

    context 'when has valid params' do
      it 'renders 201' do
        action

        expect(response).to have_http_status(201)
      end

      it 'creates one item' do
        expect { action }.to(change { RepositoryStatusItem.count }.by(1))
      end

      it 'matchs expected response' do
        action

        expect(response).to match_json_schema('status_items/resource')
      end
    end

    context 'when has AR errors' do
      let(:attributes) do
        {
          data: {
            type: 'inventory_status_items',
            attributes: {
              icon: 'icon'
            }
          }
        }
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end

    context 'when user does not has manage permissions' do
      it 'renders 403' do
        @user_team.role = :guest
        @user_team.save

        action

        expect(response).to have_http_status(403)
      end

      it 'does not creats an item' do
        @user_team.role = :guest
        @user_team.save

        expect { action }.not_to(change { RepositoryStatusItem.count })
      end
    end

    context 'when user is not part of the team' do
      let(:team) { @team2 }

      it 'renders 403' do
        action

        expect(response).to have_http_status(403)
      end
    end

    context 'when there is no inventory' do
      let(:inventory) { @wrong_inventory }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when there is no column' do
      let(:column) { @wrong_column }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when column_type is wrong' do
      let(:column) { @list_column }

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end
  end

  describe 'PUT status_item, #update' do
    let(:team) { @team1 }
    let(:inventory) { @inventory }
    let(:column) { @status_column }
    let(:status_item) { @status_column.repository_status_items.first }
    let(:attributes) do
      {
        data: {
          id: status_item.id,
          type: 'inventory_status_items',
          attributes: {
            status: 'new_status_name',
            icon: 'icon'
          }
        }
      }
    end
    let(:action) do
      put(api_v1_team_inventory_column_status_item_path(
            team_id: team.id,
            inventory_id: inventory.id,
            column_id: column.id,
            id: status_item.id
          ), params: attributes, headers: @valid_headers)
    end

    context 'when has valid params' do
      it 'renders 200' do
        action

        expect(response).to have_http_status(200)
      end

      it 'updates status on item' do
        expect { action }.to(change { status_item.reload.status })
      end

      it 'matchs expected response' do
        action

        expect(response).to match_json_schema('status_items/resource')
      end
    end

    context 'when has AR errors' do
      let(:attributes) do
        {
          data: {
            id: status_item.id,
            type: 'inventory_status_items',
            attributes: {
              status: 's',
              icon: 'icon'
            }
          }
        }
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end

      it 'does not update status on item' do
        expect { action }.not_to(change { status_item.reload.status })
      end
    end

    context 'when status_item does not extists' do
      let(:status_item) { @wrong_status_item }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when user does not has manage permissions' do
      it 'renders 403' do
        @user_team.role = :guest
        @user_team.save

        action

        expect(response).to have_http_status(403)
      end
    end

    context 'when user is not part of the team' do
      let(:team) { @team2 }

      it 'renders 403' do
        action

        expect(response).to have_http_status(403)
      end
    end

    context 'when there is no inventory' do
      let(:inventory) { @wrong_inventory }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when there is no column' do
      let(:column) { @wrong_column }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when column_type is wrong' do
      let(:column) { @list_column }

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end
  end

  describe 'DELETE step, #destroy' do
    let(:team) { @team1 }
    let(:inventory) { @inventory }
    let(:column) { @status_column }
    let(:status_item) { @status_column.repository_status_items.first }
    let(:action) do
      delete(api_v1_team_inventory_column_status_item_path(
               team_id: team.id,
               inventory_id: inventory.id,
               column_id: column.id,
               id: status_item.id
             ), headers: @valid_headers)
    end

    context 'when has valid params' do
      it 'renders 200' do
        action

        expect(response).to have_http_status(200)
      end

      it 'delets one item' do
        expect { action }.to(change { RepositoryStatusItem.count }.by(-1))
      end
    end

    context 'when user does not has manage permissions' do
      it 'renders 403' do
        @user_team.role = :guest
        @user_team.save

        action

        expect(response).to have_http_status(403)
      end

      it 'does not delets any item' do
        @user_team.role = :guest
        @user_team.save

        expect { action }.not_to(change { RepositoryStatusItem.count })
      end
    end

    context 'when status_item does not extists' do
      let(:status_item) { @wrong_status_item }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when user is not part of the team' do
      let(:team) { @team2 }

      it 'renders 403' do
        action

        expect(response).to have_http_status(403)
      end
    end

    context 'when there is no inventory' do
      let(:inventory) { @wrong_inventory }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when there is no column' do
      let(:column) { @wrong_column }

      it 'renders 404' do
        action

        expect(response).to have_http_status(404)
      end
    end

    context 'when column_type is wrong' do
      let(:column) { @list_column }

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end
  end
end
