require 'rails_helper'

describe ClientApi::Teams::TeamsController, type: :controller, broken: true do
  login_user

  before do
    @user_one = User.first
    @user_two = create :user, email: 'sec_user@asdf.com'
    @team_one = create :team, created_by: @user_one
    @team_two = create :team, name: 'Team two', created_by: @user_two
    create :user_team, team: @team_one, user: @user_one, role: 2
  end

  describe 'GET #index' do
    it 'should return HTTP success response' do
      get :index, format: :json
      expect(response).to be_success
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    before do
      @team_one.update_attribute(:name, 'My Team')
      @team_one.update_attribute(:description, 'Lorem ipsum ipsum')
    end

    it 'should return HTTP success response' do
      post :create, params: { team: { name: 'My New Team' } }, as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'should return HTTP unprocessable_entity response if name too short' do
      @team_one.update_attribute(
        :name,
        ('a' * (Constants::NAME_MIN_LENGTH - 1)).to_s
      )
      post :create, params: { team: @team_one }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'should return HTTP unprocessable_entity response if name too long' do
      @team_one.update_attribute(
        :name,
        ('a' * (Constants::NAME_MAX_LENGTH + 1)).to_s
      )
      post :create, params: { team: @team_one }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'should return HTTP unprocessable_entity response if description too long' do
      @team_one.update_attribute(
        :description,
        ('a' * (Constants::TEXT_MAX_LENGTH + 1)).to_s
      )
      post :create, params: { team: @team_one }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #change_team' do
    it 'should return HTTP success response' do
      create :user_team, team: @team_two, user: @user_one, role: 2
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
      create :user_team, team: @team_two, user: @user_one, role: 2
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
      user_team
      post :update,
           params: { team_id: @team_two.id,
                     team: { description: 'My description' } },
           as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'should return HTTP unprocessable_entity response iput not valid' do
      user_team
      post :update,
           params: {
             team_id: @team_two.id,
             team: {
               description: "super long: #{'a' * Constants::TEXT_MAX_LENGTH}"
             }
           },
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET #current_team' do
    let(:subject) { get :current_team, as: :json }
    it { is_expected.to have_http_status(:ok) }
  end
end
