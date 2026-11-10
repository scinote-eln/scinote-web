# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::UserSettingsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:json) { JSON.parse(response.body) }

  def store!(key, value)
    user.settings[key] = value
    user.save!
  end

  describe 'GET show' do
    it 'returns the stored value of the requested key' do
      store!('theme', 'dark')
      get :show, params: { key: 'theme' }, format: :json
      expect(response).to have_http_status(:success)
      expect(json['data']).to eq 'dark'
    end

    it 'returns null data for a key that was never stored' do
      get :show, params: { key: 'unknown_key' }, format: :json
      expect(response).to have_http_status(:success)
      expect(json['data']).to be_nil
    end

    it 'does not return settings of another user' do
      other = create :user
      other.settings['theme'] = 'dark'
      other.save!
      get :show, params: { key: 'theme' }, format: :json
      expect(json['data']).to be_nil
    end
  end

  describe 'PUT update' do
    context 'without whitelisted keys' do
      it 'ignores every key and still responds with ok' do
        put :update, params: { settings: [{ key: 'theme', data: 'dark' }] }, as: :json
        expect(response).to have_http_status(:ok)
        expect(user.reload.settings['theme']).to be_nil
      end
    end

    context 'with whitelisted keys' do
      before do
        stub_const('Extends::WHITELISTED_USER_SETTINGS', ['theme', 'task_step_states', 'result_states'])
      end

      it 'stores a plain setting' do
        put :update, params: { settings: [{ key: 'theme', data: 'dark' }] }, as: :json
        expect(response).to have_http_status(:ok)
        expect(user.reload.settings['theme']).to eq 'dark'
      end

      it 'stores several settings from one request' do
        put :update, params: { settings: [{ key: 'theme', data: 'light' },
                                          { key: 'result_states', data: { '7' => true } }] }, as: :json
        expect(response).to have_http_status(:ok)
        expect(user.reload.settings['theme']).to eq 'light'
        expect(user.reload.settings['result_states']).to eq('7' => true)
      end

      it 'ignores non-whitelisted keys in the same request' do
        put :update, params: { settings: [{ key: 'theme', data: 'light' },
                                          { key: 'not_allowed', data: 'x' }] }, as: :json
        expect(user.reload.settings['theme']).to eq 'light'
        expect(user.reload.settings).not_to have_key('not_allowed')
      end

      %w(task_step_states result_states).each do |key|
        it "merges collapsed #{key} and removes expanded ones" do
          store!(key, { '1' => true, '2' => true })

          put :update, params: { settings: [{ key: key, data: { '2' => false, '3' => true } }] }, as: :json

          expect(response).to have_http_status(:ok)
          expect(user.reload.settings[key]).to eq('1' => true, '3' => true)
        end

        it "starts from an empty #{key} state when none was stored" do
          put :update, params: { settings: [{ key: key, data: { '5' => true } }] }, as: :json

          expect(user.reload.settings[key]).to eq('5' => true)
        end
      end

      it 'returns an error when the user cannot be saved' do
        allow_any_instance_of(User).to receive(:save).and_return(false)
        put :update, params: { settings: [{ key: 'theme', data: 'dark' }] }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['error']).to eq 'Failed to update settings'
        expect(json['details']).to be_an(Array)
      end
    end

    it 'requires the settings parameter' do
      expect { put :update, params: { theme: 'dark' }, as: :json }
        .to raise_error(ActionController::ParameterMissing)
    end
  end
end
