require 'rails_helper'

describe ClientApi::Users::UserTeamsController, type: :controller, broken: true do
  login_user
  let(:user_one) { User.first }
  let(:user_two) { create :user, email: Faker::Internet.email }
  let(:team) { create :team }
  let(:user_team) { create :user_team, team: team, user: user_one }

  describe 'DELETE #leave_team' do
    it 'should return HTTP success if user can leave the team' do
      create :user_team, team: team, user: user_two
      delete :leave_team,
             params: { team: team.id, user_team: user_team.id },
             format: :json
      expect(response).to be_success
      expect(response).to have_http_status(:ok)
    end

    it 'should return HTTP unprocessable_entity if user can\'t ' \
       'leave the team' do
      delete :leave_team,
             params: { team: team.id, user_team: user_team.id },
             format: :json
      expect(response).to_not be_success
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'should return HTTP unprocessable_entity if no params given' do
      delete :leave_team, format: :json
      expect(response).to_not be_success
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #update_role' do
    it 'should return HTTP success if user can leave the team' do
      create :user_team, team: team, user: user_two, role: 2
      post :update_role,
           params: { team: team.id,
                     user_team: user_team.id,
                     role: 'normal_user' },
           format: :json
      expect(response).to be_success
      expect(response).to have_http_status(:ok)
    end

    it 'should return HTTP unprocessable_entity if user can\'t ' \
       'leave the team' do
      post :update_role,
           params: { team: team.id,
                     user_team: user_team.id,
                     role: 'normal_user' },
           format: :json
      expect(response).to_not be_success
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE #remove_user' do
    it 'should return HTTP success if user can be removed' do
      user_team
      user_team_two = create :user_team, team: team, user: user_two
      post :remove_user,
           params: { team: team.id, user_team: user_team_two.id },
           format: :json
      expect(response).to be_success
      expect(response).to have_http_status(:ok)
    end

    it 'should return HTTP unprocessable_entity if user can\'t ' \
       'be removed' do
      post :remove_user,
           params: { team: team.id,
                     user_team: user_team.id,
                     role: 'normal_user' },
           format: :json
      expect(response).to_not be_success
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
