require 'rails_helper'

describe ClientApi::PermissionsController, type: :controller do
  login_user

  describe '#status' do
    let(:params) do
      { parsePermission: ['can_view_team'], resource: 'UserTeam' }
    end
    let(:subject) { post :status, format: :json, params: params }
    it { is_expected.to be_success }
  end
end
