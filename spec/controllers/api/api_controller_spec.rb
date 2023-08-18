require 'rails_helper'

describe Api::ApiController, type: :controller do
  describe 'GET #status' do
    before do
      get :status
    end

    it 'Returns HTTP success' do
      expect(response).to have_http_status(200)
    end

    it 'Response with correct JSON status structure' do
      hash_body = nil
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body).to include(message: I18n.t('api.core.status_ok'))
      expect(hash_body).to include('versions')

      Extends::API_VERSIONS.each do |ver|
        expect(hash_body['versions']).to include(
          'version' => ver,
          'baseUrl' => "/api/#{ver}/"
        )
      end
    end
  end
end
