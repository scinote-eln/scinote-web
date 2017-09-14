require 'rails_helper'

describe ClientApi::Teams::TeamsController, type: :controller do
  login_user

  before do
    @user_one = User.first
    @user_two = FactoryGirl.create(:user, email: 'sec_user@asdf.com')
    @team_one = FactoryGirl.create :team
    @team_two = FactoryGirl.create :team, name: 'Team two'
    FactoryGirl.create :user_team, team: @team_one, user: @user_one, role: 2
  end

  describe 'GET #index' do
    it 'should return HTTP success response' do
      get :index, format: :json
      expect(response).to be_success
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #change_team' do
    it 'should return HTTP success response' do
      FactoryGirl.create :user_team, team: @team_two, user: @user_one, role: 2
      @user_one.update_attribute(:current_team_id, @team_one.id)
      post :change_team, params: { team_id: @team_two.id }, as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'should return HTTP unprocessable_entity response if user not in team' do
      @user_one.update_attribute(:current_team_id, @team_one.id)
      post :change_team, params: { team_id: @team_two.id }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'should return HTTP success response if same team as current' do
      @user_one.update_attribute(:current_team_id, @team_one.id)
      post :change_team, params: { team_id: @team_one.id }, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #details' do
    it 'should return HTTP success response' do
      FactoryGirl.create :user_team, team: @team_two, user: @user_one, role: 2
      @user_one.update_attribute(:current_team_id, @team_one.id)
      get :details, params: { team_id: @team_two.id }, as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'should return HTTP unprocessable_entity response if user not in team' do
      @user_one.update_attribute(:current_team_id, @team_one.id)
      get :details, params: { team_id: @team_two.id }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'should return HTTP unprocessable_entity response if team_id not valid' do
      get :details, params: { team_id: 'banana' }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #update' do
    let(:user_team) do
      create :user_team, team: @team_two, user: @user_one, role: 2
    end

    it 'should return HTTP success response' do
      post :change_team,
           params: { team_id: @team_two.id, description: 'My description' },
           as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'should return HTTP unprocessable_entity response iput not valid' do
      post :change_team,
           params: {
             team_id: @team_two.id,
             description: "super long: #{'a' * Constants::TEXT_MAX_LENGTH}"
           },
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
