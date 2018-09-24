require 'rails_helper'

describe Api::ApiController, type: :controller do
  describe 'GET #status' do
    before do
      get :status
    end

    it 'Returns HTTP success' do
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'Response with correct JSON status structure' do
      hash_body = nil
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to match(
        'message' => I18n.t('api.core.status_ok'),
        'versions' => [{ 'version' => '20170715',
                         'baseUrl' => '/api/20170715/' }]
      )
    end
  end
end
