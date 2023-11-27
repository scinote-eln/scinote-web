# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  describe 'POST #create' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user.confirm
    end

    let(:user) { create :user }
    let(:password) { 'asdf1243' }
    let(:params) do
      { user: {
        email: user.email,
        password: password
      } }
    end

    let(:action) do
      post :create, params: params
    end

    context 'when have invalid email or password' do
      let(:password) { '123' }

      it 'returns error message' do
        action

        expect(flash[:alert]).to eq('Invalid Email or password.')
      end

      it 'does not set current user' do
        expect { action }.not_to(change { subject.current_user })
      end
    end

    context 'when have valid email and password' do
      context 'when user has 2FA disabled' do
        it 'returns successfully log in' do
          action

          expect(flash[:notice]).to eq('Logged in successfully.')
        end

        it 'sets current user' do
          expect { action }.to(change { subject.current_user }.from(nil).to(User))
        end
      end

      context 'when user has 2FA enabled' do
        it 'redirects to 2fa code form, sets the session and does not sign in the user' do
          user.two_factor_auth_enabled = true
          user.save!
          expect(action).to redirect_to(users_two_factor_auth_path)
          expect(action.request.session[:otp_user_id]).to eq user.id
          expect { action }.not_to(change { subject.current_user })
        end
      end

      context 'when local passwords disabled' do
        it 'returns error message' do
          Rails.application.config.x.disable_local_passwords = true
          action
          expect(flash[:alert]).to eq(I18n.t('devise.failure.auth_method_disabled'))
        end

        it 'does not set current user' do
          expect { action }.not_to(change { subject.current_user })
        end
      end
    end
  end

  describe 'POST #authenticate_with_two_factor' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user.confirm
    end

    let(:user) { create :user }
    let(:params) { { otp: '123123' } }
    let(:otp_user_id) { user.id }
    let(:action) do
      post :authenticate_with_two_factor, params: params, session: { otp_user_id: otp_user_id }
    end

    context 'when have valid otp' do
      it 'sets current user' do
        allow_any_instance_of(User).to receive(:valid_otp?).and_return(true)

        expect { action }.to(change { subject.current_user }.from(nil).to(User))
      end
    end

    context 'when have invalid valid otp' do
      it 'returns error message' do
        allow_any_instance_of(User).to receive(:valid_otp?).and_return(nil)
        action

        expect(flash[:alert]).to eq(I18n.t('devise.sessions.2fa.error_message'))
      end

      it 'does not set current user' do
        allow_any_instance_of(User).to receive(:valid_otp?).and_return(nil)

        expect { action }.not_to(change { subject.current_user })
      end
    end

    context 'when user is not found' do
      let(:otp_user_id) { -1 }

      it 'returns error message' do
        action

        expect(flash[:alert]).to eq('Cannot find user!')
      end
    end
  end
end
