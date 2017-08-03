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

  describe 'Post #authenticate' do
    let(:user) { create(:user) }

    context 'When valid request' do
      before do
        post :authenticate, params: { email: user.email,
                                      password: user.password,
                                      grant_type: 'password' }
      end

      it 'Returns HTTP success' do
        expect(response).to have_http_status(200)
      end

      it 'Returns valid JWT token' do
        token = nil
        expect { token = json['access_token'] }.not_to raise_exception
        user_id = nil
        expect { user_id = decode_token(token) }.not_to raise_exception
        expect(user_id).to eq(user.id)
      end
    end

    context 'When invalid password in request' do
      it 'Returns HTTP error' do
        post :authenticate, params: { email: user.email,
                                      password: 'wrong_password',
                                      grant_type: 'password' }
        expect(response).to have_http_status(400)
      end
    end

    context 'When no grant_type in request' do
      it 'Returns HTTP error' do
        post :authenticate, params: { email: user.email,
                                      password: user.password }
        expect(response).to have_http_status(400)
      end
    end
  end
end
