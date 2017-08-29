require 'rails_helper'

describe ClientApi::Users::UserTeamsController, type: :controller do
  describe 'DELETE #leave_team' do
    login_user
    before do
      @user_one = User.first
      @user_two = FactoryGirl.create(:user, email: 'sec_user@asdf.com')
      @team = FactoryGirl.create :team
      FactoryGirl.create :user_team, team: @team, user: @user_one, role: 2
    end

    it 'Returns HTTP success if user can leave the team' do
      FactoryGirl.create :user_team, team: @team, user: @user_two, role: 2
      delete :leave_team, params: { team: @team.id }, format: :json
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'Returns HTTP unprocessable_entity if user can\'t leave the team' do
      delete :leave_team, params: { team: @team.id }, format: :json
      expect(response).to_not be_success
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'Returns HTTP unprocessable_entity if no params given' do
      delete :leave_team, format: :json
      expect(response).to_not be_success
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
