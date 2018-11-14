require 'rails_helper'

describe Api::ApiController, type: :controller do
  describe 'GET #health' do
    before do
      get :health
    end

    it 'Returns HTTP success and with correct text' do
      expect(response).to be_success
      expect(response).to have_http_status(200)
      expect(response.body).to match('RUNNING')
    end
  end

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
        'versions' => [{ 'version' => 'v1',
                         'baseUrl' => '/api/v1/' }]
      )
    end
  end
end
