# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  around do |example|
    original = Rails.application.config.x.disable_local_passwords
    Rails.application.config.x.disable_local_passwords = false
    example.run
  ensure
    Rails.application.config.x.disable_local_passwords = original
  end

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

        expect(flash[:alert]).to eq('Invalid email or password.')
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
          expect(user.reload.two_factor_auth_enabled).to be true
          expect(subject.current_user).to be_nil
          expect(action).to redirect_to(users_two_factor_auth_path)
          expect(request.session[:otp_user_id]).to eq user.id
          expect(subject.current_user).to be_nil
          expect(warden.authenticated?(:user)).to be false
        end
      end

      context 'when local passwords disabled' do
        before { Rails.application.config.x.disable_local_passwords = true }

        it 'returns error message' do
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

  describe 'GET #new' do
    include_context 'without compiled assets'
    before { @request.env['devise.mapping'] = Devise.mappings[:user] }

    render_views

    it 'renders the sign in page' do
      get :new

      expect(response).to have_http_status(:ok)
      expect(assigns(:simple_sign_in)).to be(false)
      expect(assigns(:oauth_authorize)).to be(false)
    end

    it 'flags simple sign in and oauth authorization' do
      get :new, params: { simple_sign_in: 'true' }, session: { 'oauth_authorize' => true }

      expect(assigns(:simple_sign_in)).to be(true)
      expect(assigns(:oauth_authorize)).to be(true)
    end

    it 'clears the unauthenticated flash when the return location is the root path' do
      get :new, session: { user_return_to: root_path },
                flash: { alert: I18n.t('devise.failure.unauthenticated') }

      expect(flash[:alert]).to be_nil
    end

    it 'keeps the unauthenticated flash for other return locations' do
      get :new, session: { user_return_to: '/projects' },
                flash: { alert: I18n.t('devise.failure.unauthenticated') }

      expect(flash[:alert]).to eq(I18n.t('devise.failure.unauthenticated'))
    end
  end

  describe 'GET #expire_in' do
    before { @request.env['devise.mapping'] = Devise.mappings[:user] }

    it 'returns 401 when nobody is signed in' do
      get :expire_in

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when signed in' do
      let(:user) { create :user, confirmed_at: Time.zone.now }

      before do
        sign_in user
        allow(controller).to receive(:user_session).and_return({ 'last_request_at' => Time.now.to_i })
      end

      it 'returns remaining session time in milliseconds without remember me' do
        user.update_columns(remember_created_at: nil)
        get :expire_in

        expect(response).to have_http_status(:ok)
        expect(response.body.to_i).to be_within(5000).of(user.timeout_in.to_i * 1000)
      end

      it 'returns the larger of remember-me and session time with an active remember cookie' do
        user.update_columns(remember_created_at: Time.current)
        get :expire_in

        expected = [Devise.remember_for.to_i * 1000, user.timeout_in.to_i * 1000].max
        expect(response.body.to_i).to be_within(5000).of(expected)
      end
    end
  end

  describe 'POST #revive_session' do
    before { @request.env['devise.mapping'] = Devise.mappings[:user] }

    it 'returns a csrf token' do
      post :revive_session

      expect(JSON.parse(response.body)['csrf_token']).to be_present
    end
  end

  describe 'GET #two_factor_recovery' do
    include_context 'without compiled assets'
    before { @request.env['devise.mapping'] = Devise.mappings[:user] }

    render_views

    it 'redirects to sign in without a pending 2FA user' do
      get :two_factor_recovery

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders the recovery form when a 2FA user is pending' do
      pending_user = create :user
      get :two_factor_recovery, session: { otp_user_id: pending_user.id }

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:two_factor_recovery)
      expect(subject.current_user).to be_nil
    end
  end

  describe 'GET #two_factor_auth' do
    include_context 'without compiled assets'
    before { @request.env['devise.mapping'] = Devise.mappings[:user] }

    render_views

    it 'renders the 2FA form and remembers the stored location' do
      get :two_factor_auth, session: { user_return_to: '/projects' }

      expect(response).to have_http_status(:ok)
      expect(assigns(:initial_page)).to eq('/projects')
    end
  end

  describe 'POST #authenticate_with_recovery_code' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user.confirm
    end

    let(:user) { create :user }

    it 'signs the user in with a valid recovery code' do
      allow_any_instance_of(User).to receive(:recover_2fa!).with('good').and_return(true)

      post :authenticate_with_recovery_code, params: { recovery_code: 'good' }, session: { otp_user_id: user.id }

      expect(subject.current_user).to eq(user)
      expect(flash[:notice]).to eq(I18n.t('devise.sessions.signed_in'))
      expect(response).to redirect_to(root_path)
    end

    it 'redirects to sign in with an invalid recovery code and drops the pending user' do
      allow_any_instance_of(User).to receive(:recover_2fa!).and_return(false)

      post :authenticate_with_recovery_code, params: { recovery_code: 'bad' }, session: { otp_user_id: user.id }

      expect(subject.current_user).to be_nil
      expect(flash[:alert]).to eq(I18n.t('devise.sessions.2fa_recovery.not_correct_code'))
      expect(response).to redirect_to(new_user_session_path)
      expect(session[:otp_user_id]).to be_nil
    end

    it 'redirects to root when the pending user does not exist' do
      pending 'bug: `redirect_to root_path && return` returns before redirecting'
      post :authenticate_with_recovery_code, params: { recovery_code: 'x' }, session: { otp_user_id: -1 }

      expect(response).to redirect_to(root_path)
    end

    it 'sets the missing user alert when the pending user does not exist' do
      post :authenticate_with_recovery_code, params: { recovery_code: 'x' }, session: { otp_user_id: -1 }

      expect(flash[:alert]).to eq(I18n.t('devise.sessions.2fa.no_user_error'))
      expect(subject.current_user).to be_nil
    end
  end

  describe 'POST #authenticate_with_two_factor extras' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user.confirm
    end

    let(:user) { create :user }

    it 'redirects to the initial page and clears the pending user on success' do
      allow_any_instance_of(User).to receive(:valid_otp?).and_return(true)

      post :authenticate_with_two_factor, params: { otp: '1', initial_page: '/projects' },
                                          session: { otp_user_id: user.id }

      expect(response).to redirect_to('/projects')
      expect(session[:otp_user_id]).to be_nil
      expect(flash[:notice]).to eq(I18n.t('devise.sessions.signed_in'))
    end

    it 're-renders the 2FA form on invalid otp' do
      allow_any_instance_of(User).to receive(:valid_otp?).and_return(false)

      post :authenticate_with_two_factor, params: { otp: '1' }, session: { otp_user_id: user.id }

      expect(response).to render_template(:two_factor_auth)
    end
  end
end
