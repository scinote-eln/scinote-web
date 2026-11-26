# frozen_string_literal: true

require 'rails_helper'

describe UserSettingsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:json) { JSON.parse(response.body) }

  describe 'GET show' do
    it 'returns the stored value' do
      user.user_settings.create!(key: 'sidebar_state', value: { 'open' => true })

      get :show, params: { key: 'sidebar_state' }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['value']).to eq('open' => true)
    end

    it 'returns 404 with a nil value for an unknown key' do
      get :show, params: { key: 'unknown_key' }, format: :json

      expect(response).to have_http_status(:not_found)
      expect(json['value']).to be_nil
    end

    it 'does not return settings of another user' do
      other = create(:user)
      other.user_settings.create!(key: 'sidebar_state', value: { 'open' => true })

      get :show, params: { key: 'sidebar_state' }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT update' do
    it 'creates a new setting' do
      expect do
        put :update, params: { key: 'sidebar_state', user_setting: { value: { open: 'yes' } } }
      end.to change { user.user_settings.where(key: 'sidebar_state').count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(user.user_settings.find_by(key: 'sidebar_state').value).to eq('open' => 'yes')
    end

    it 'replaces the value of an existing setting' do
      user.user_settings.create!(key: 'sidebar_state', value: { 'open' => 'yes' })

      expect do
        put :update, params: { key: 'sidebar_state', user_setting: { value: { open: 'no' } } }
      end.not_to(change { user.user_settings.count })

      expect(user.user_settings.find_by(key: 'sidebar_state').value).to eq('open' => 'no')
    end

    %w(result_states task_step_states result_template_states).each do |key|
      context "with #{key}" do
        it 'merges collapsed objects and removes expanded ones' do
          user.user_settings.create!(key: key, value: { '1' => true, '2' => true })

          put :update, params: { key: key, user_setting: { value: { '2' => false, '3' => true } } }, as: :json

          expect(response).to have_http_status(:ok)
          expect(user.user_settings.find_by(key: key).value).to eq('1' => true, '3' => true)
        end

        it 'starts from an empty state' do
          put :update, params: { key: key, user_setting: { value: { '5' => true } } }, as: :json

          expect(user.user_settings.find_by(key: key).value).to eq('5' => true)
        end
      end
    end

    it 'requires a user_setting parameter' do
      expect do
        put :update, params: { key: 'sidebar_state' }
      end.to raise_error(ActionController::ParameterMissing)
    end
  end
end
