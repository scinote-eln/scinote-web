require 'rails_helper'

describe ClientApi::PermissionsController, type: :controller, broken: true do
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

    it 'raises an error if no required permissions passed' do
      expect do
        post :status,
             format: :json,
             params: { resource: { type: 'Team', id: team.id } }
      end
        .to raise_error(NoMethodError)
    end

    it 'raises an error if no required resource type invalid' do
      expect do
        post :status,
             format: :json,
             params: { requiredPermissions: ['can_read_team'],
                       resource: { type: 'Banana', id: team.id } }
      end
        .to raise_error(ArgumentError)
    end

    it 'raises an error if no required resource id is not present' do
      expect do
        post :status,
             format: :json,
             params: { requiredPermissions: ['can_read_team'],
                       resource: { type: 'Team' } }
      end
        .to raise_error(ArgumentError)
    end

    context 'raises an error if can\'t find permission invalid when resource' do
      it 'is absent' do
        expect do
          post :status,
               format: :json,
               params: { requiredPermissions: ['can_throw_bananas'] }
        end
          .to raise_error(ArgumentError)
      end

      it 'is present' do
        expect do
          post :status,
               format: :json,
               params: { requiredPermissions: ['can_throw_bananas'],
                         resource: { type: 'Team', id: team.id } }
        end
          .to raise_error(ArgumentError)
      end
    end
  end
end
