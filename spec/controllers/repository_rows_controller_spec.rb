# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRowsController, type: :controller do
  login_user
  render_views
  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, team: team, user: user }
  let!(:repository) { create :repository, team: team, created_by: user }
  let!(:repository_state) do
    RepositoryTableState.create(
      repository: repository,
      user: user,
      state: Constants::REPOSITORY_TABLE_DEFAULT_STATE
    )
  end
  let!(:repository_row) do
    create :repository_row, repository: repository,
                            created_by: user,
                            last_modified_by: user
  end

  let!(:user_two) { create :user, email: 'new@user.com' }
  let!(:team_two) { create :team, created_by: user }
  let!(:user_team_two) { create :user_team, team: team_two, user: user_two }
  let!(:repository_two) do
    create :repository, team: team_two, created_by: user_two
  end
  let!(:repository_row_two) do
    create :repository_row, repository: repository_two,
                            created_by: user_two,
                            last_modified_by: user_two
  end

  describe '#show' do
    it 'unsuccessful response with non existing id' do
      get :show, format: :json, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end

    it 'unsuccessful response with unpermitted id' do
      get :show, format: :json, params: { id: repository_row_two.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'successful response' do
      get :show, format: :json, params: { id: repository_row.id }
      expect(response).to have_http_status(:success)
    end
  end

  context '#index' do
    before do
      repository.repository_rows.destroy_all
      110.times do |index|
        create :repository_row, name: "row (#{index})",
                                repository: repository,
                                created_by: user,
                                last_modified_by: user
      end
    end

    describe 'json object' do
      it 'returns a valid object' do
        params = { order: { 0 => { column: '4', dir: 'asc' } },
                   drow: '0',
                   search: { value: '' },
                   length: '10',
                   start: '1',
                   repository_id: repository.id }
        get :index, params: params, format: :json

        expect(response.status).to eq 200
        expect(response).to match_response_schema('repository_row_datatables')
      end
    end

    describe 'pagination' do
      it 'returns first 10 records' do
        params = { order: { 0 => { column: '4', dir: 'asc' } },
                   drow: '0',
                   search: { value: '' },
                   length: '10',
                   start: '1',
                   repository_id: repository.id }
        get :index, params: params, format: :json
        response_body = JSON.parse(response.body)
        expect(response_body['data'].length).to eq 10
        expect(response_body['data'].first['3']).to eq 'row (0)'
      end

      it 'returns next 10 records' do
        params = { order: { 0 => { column: '4', dir: 'asc' } },
                   drow: '0',
                   search: { value: '' },
                   length: '10',
                   start: '11',
                   repository_id: repository.id }
        get :index, params: params, format: :json
        response_body = JSON.parse(response.body)
        expect(response_body['data'].length).to eq 10
        expect(response_body['data'].first['3']).to eq 'row (10)'
      end

      it 'returns first 25 records' do
        params = { order: { 0 => { column: '4', dir: 'desc' } },
                   drow: '0',
                   search: { value: '' },
                   length: '25',
                   start: '1',
                   repository_id: repository.id }
        get :index, params: params, format: :json
        response_body = JSON.parse(response.body)
        expect(response_body['data'].length).to eq 25
      end
    end
  end

  describe 'POST #copy_records' do
    it 'returns a success response' do
      post :copy_records, params: { repository_id: repository.id,
                                    selected_rows: [repository_row.id] }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { repository_id: repository.id, repository_row: { name: 'row_name' } }
    end

    it 'calls create activity for creating inventory item' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :create_item_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      {
        repository_id: repository.id,
        id: repository_row.id,
        repository_row: { name: 'row_name' }
      }
    end

    it 'calls create activity for editing intentory item' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :edit_item_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'POST delete_records' do
    let(:action) { post :delete_records, params: params, format: :json }
    let(:params) do
      { repository_id: repository.id, selected_rows: [repository_row.id] }
    end

    it 'calls create activity for deleting inventory items' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_item_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
