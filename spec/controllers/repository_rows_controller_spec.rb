require 'rails_helper'

describe RepositoryRowsController, type: :controller do
  login_user
  render_views
  let(:user) { User.first }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, team: team, user: user }
  let!(:repository) { create :repository, team: team, created_by: user }
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
      get :show, format: :json, params: { id: 999999 }
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
end
