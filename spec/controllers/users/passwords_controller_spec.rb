# frozen_string_literal: true

require 'rails_helper'

describe Users::PasswordsController, type: :controller do
  include_context 'without compiled assets'
  render_views

  let(:user) { create :user, confirmed_at: Time.zone.now }

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    ActionMailer::Base.deliveries.clear
  end

  describe 'POST #create' do
    it 'sends reset instructions and redirects for a known email' do
      expect { post :create, params: { user: { email: user.email } } }
        .to change { user.reload.reset_password_token }.from(nil)

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to eq(I18n.t('devise.passwords.send_instructions'))
      expect(ActionMailer::Base.deliveries.map(&:to)).to include([user.email])
    end

    it 'redirects the same way for an unknown email (paranoid mode)' do
      post :create, params: { user: { email: 'nobody@example.com' } }

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to be_present
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 're-renders the form with an alert when email is blank' do
      post :create, params: { user: { email: '' } }

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
      expect(flash.now[:alert]).to eq(I18n.t('devise.errors.email.empty'))
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe 'PUT #update' do
    let!(:raw_token) { user.send_reset_password_instructions }
    let(:new_password) { 'N3wSecretPass!x' }
    let(:params) do
      { user: { reset_password_token: raw_token, password: new_password, password_confirmation: new_password } }
    end

    it 'changes the password, signs the user in and redirects' do
      put :update, params: params

      expect(user.reload.valid_password?(new_password)).to be(true)
      expect(subject.current_user).to eq(user)
      expect(flash[:notice]).to eq(I18n.t('devise.passwords.updated'))
      expect(response).to have_http_status(:redirect)
    end

    it 'unlocks a locked account' do
      user.update_columns(locked_at: Time.current, failed_attempts: 5, unlock_token: 'abc')

      put :update, params: params

      expect(user.reload.locked_at).to be_nil
    end

    it 'does not sign in and redirects to sign in when 2FA is enabled' do
      user.update!(two_factor_auth_enabled: true)

      put :update, params: params

      expect(user.reload.valid_password?(new_password)).to be(true)
      expect(subject.current_user).to be_nil
      expect(flash[:notice]).to eq(I18n.t('devise.passwords.updated_not_active'))
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders the edit form when the token is invalid' do
      params[:user][:reset_password_token] = 'wrong'

      put :update, params: params

      expect(response).to render_template(:edit)
      expect(subject.current_user).to be_nil
    end

    it 'renders the edit form when confirmation does not match' do
      params[:user][:password_confirmation] = 'different'

      put :update, params: params

      expect(response).to render_template(:edit)
      expect(user.reload.valid_password?(new_password)).to be(false)
    end
  end
end
