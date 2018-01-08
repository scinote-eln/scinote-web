require 'rails_helper'

describe ClientApi::PermissionsController, type: :controller do
  login_user

  describe '#status' do
    let!(:user) { User.first || create(:user) }
    let!(:team) { create :team, created_by: user }
    let!(:user_team) { create :user_team, user: user, team: team, role: 2 }
    let(:params) do
      { requiredPermissions: ['can_read_team'],
        resource: { type: 'Team', id: team.id } }
    end

    let(:subject) { post :status, format: :json, params: params }
    it { is_expected.to be_success }

    it 'returns an object with the permission' do
      body = JSON.parse(subject.body)
      expect(body).to eq('can_read_team' => true)
    end
  end
end
