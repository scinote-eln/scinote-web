require 'rails_helper'

describe ClientApi::ConfigurationsController, type: :controller, broken: true do
  login_user

  describe '#about_scinote' do
    let(:subject) { get :about_scinote, format: :json }
    it { is_expected.to be_success }
  end
end
