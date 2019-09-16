require 'rails_helper'

describe ClientApi::Users::InvitationsController, type: :controller, broken: true do
  login_user
  let(:user_one) { User.first }
  let(:team_one) { create :team }
  let(:emails_one) { Array.new(3) { Faker::Internet.email } }

  describe '#invite_users' do
    it 'returns HTTP success if users were invited' do
      post :invite_users, params: { user_role: 'normal_user',
                                    emails: emails_one },
                          format: :json
      expect(response).to be_success
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('client_api/users/invite_users')
    end

    it 'returns HTTP success if users were invited to team' do
      create :user_team, team: team_one, user: user_one
      post :invite_users, params: { team_id: team_one.id,
                                    user_role: 'normal_user',
                                    emails: emails_one },
                          format: :json
      expect(response).to be_success
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('client_api/users/invite_users')
    end

    it 'returns HTTP unprocessable_entity if users can\'t be invited to team' do
      post :invite_users, params: { team_id: team_one.id,
                                    user_role: 'normal_user',
                                    emails: emails_one },
                          format: :json
      expect(response).to_not be_success
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.media_type).to eq 'application/json'
    end
  end
end
