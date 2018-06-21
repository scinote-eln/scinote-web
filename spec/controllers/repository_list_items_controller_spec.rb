require 'rails_helper'

describe RepositoryListItemsController, type: :controller do
  login_user
  render_views
  let(:user) { User.first }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, team: team, user: user }
  let!(:repository) { create :repository, team: team, created_by: user }
  let!(:repository_column_one) do
    create :repository_column, repository: repository,
                               created_by: user,
                               name: 'List Value',
                               data_type: 'RepositoryListValue'
  end
  let!(:repository_list_item_one) do
    create :repository_list_item, data: 'item one',
                                  repository: repository,
                                  repository_column: repository_column_one
  end
  let!(:repository_list_item_two) do
    create :repository_list_item, data: 'item two',
                                  repository: repository,
                                  repository_column: repository_column_one
  end

  let!(:user_two) { create :user, email: 'new@user.com' }
  let!(:team_two) { create :team, created_by: user }
  let!(:user_team_two) { create :user_team, team: team_two, user: user_two }
  let!(:repository_two) do
    create :repository, team: team_two, created_by: user_two
  end
  let!(:user_two_repository_column_two) do
    create :repository_column, repository: repository_two,
                               created_by: user_two,
                               name: 'List Value',
                               data_type: 'RepositoryListValue'
  end
  let!(:user_two_repository_list_item_one) do
    create :repository_list_item,
           data: 'item one of user two',
           repository: repository_two,
           repository_column: user_two_repository_column_two,
           created_by: user_two,
           last_modified_by: user_two
  end
  let!(:user_two_repository_list_item_two) do
    create :repository_list_item,
           data: 'item two of user two',
           repository: repository_two,
           repository_column: user_two_repository_column_two,
           created_by: user_two,
           last_modified_by: user_two
  end

  describe '#search' do
    let(:params) { { q: '', column_id: repository_column_one.id } }
    it 'returns all column\'s list items' do
      get :search, format: :json, params: params
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['list_items'].count).to eq 2
    end

    it 'returns queried item' do
      params[:q] = 'item one'
      get :search, format: :json, params: params
      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body['list_items'].count).to eq 1
      expect(body['list_items'].first['data']).to eq 'item one'
    end

    it 'returns a 404 error if column does not exist' do
      params[:column_id] = 999999
      get :search, format: :json, params: params
      expect(response).to have_http_status(:not_found)
    end

    it 'returns a 403 error user does not have permissions' do
      params[:column_id] = user_two_repository_column_two.id
      get :search, format: :json, params: params
      expect(response).to have_http_status(:forbidden)
    end
  end
end
