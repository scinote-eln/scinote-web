# frozen_string_literal: true

require 'rails_helper'

describe Users::OmniauthCallbacksController, type: :controller do
  let(:settings_values) { {} }

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    allow(ApplicationSettings).to receive(:instance)
      .and_return(instance_double(ApplicationSettings, values: settings_values))
    allow(controller).to receive(:sso_enabled?).and_return(true)
  end

  def auth_hash(provider:, uid: 'uid-123', email: 'sso.user@example.com', extra: {})
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { email: email, first_name: 'Sso', last_name: 'User' },
      extra: extra
    )
  end

  shared_examples 'an SSO callback' do |action, provider_name, conf_key|
    let(:provider) { provider_name }
    let(:provider_conf) { { 'enabled' => true } }
    let(:settings_values) { { conf_key => provider_conf } }
    let(:auth) { auth_hash(provider: provider) }

    before { request.env['omniauth.auth'] = auth }

    it 'renders 403 when SSO is disabled' do
      allow(controller).to receive(:sso_enabled?).and_return(false)

      get action

      expect(response).to have_http_status(:forbidden)
    end

    it 'redirects signed in users to connected accounts' do
      sign_in create(:user, confirmed_at: Time.zone.now)

      get action

      expect(response).to redirect_to(connected_accounts_path)
    end

    it 'signs in a user with a matching identity' do
      user = create :user, confirmed_at: Time.zone.now
      create :user_identity, user: user, provider: provider, uid: 'uid-123'

      get action

      expect(response).to have_http_status(:redirect)
      expect(controller.current_user).to eq user
    end

    it 'creates a new confirmed user with identity' do
      expect { get action }.to change(User, :count).by(1)

      user = User.find_by(email: 'sso.user@example.com')
      expect(user.full_name).to eq 'Sso User'
      expect(user.confirmed_at).to be_present
      expect(user.user_identities.pluck(:provider, :uid)).to eq [[provider, 'uid-123']]
      expect(controller.current_user).to eq user
      expect(flash[:notice]).to be_present
    end

    context 'when user creation is disabled and user with email exists' do
      let(:provider_conf) { { 'no_new_user_creation' => true, 'auto_link_on_sign_in' => true } }

      it 'links the identity to the existing account' do
        user = create :user, email: 'sso.user@example.com'

        get action

        expect(user.user_identities.reload.pluck(:uid)).to eq ['uid-123']
        expect(user.reload.confirmed_at).to be_present
        expect(controller.current_user).to eq user
      end
    end

    it 'redirects with failure when new user cannot be saved' do
      request.env['omniauth.auth'] = auth_hash(provider: provider, email: 'not-an-email')

      expect { get action }.not_to change(User, :count)

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe 'GET okta' do
    include_examples 'an SSO callback', :okta, 'okta', 'okta'

    it 'redirects with error when okta is not configured' do
      allow(ApplicationSettings).to receive(:instance)
        .and_return(instance_double(ApplicationSettings, values: {}))
      request.env['omniauth.auth'] = auth_hash(provider: 'okta')

      get :okta

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include(I18n.t('devise.okta.errors.generic'))
    end
  end

  describe 'GET openid_connect' do
    include_examples 'an SSO callback', :openid_connect, 'openid_connect', 'openid_connect'

    it 'returns error when no local user can be mapped' do
      allow(ApplicationSettings).to receive(:instance)
        .and_return(instance_double(ApplicationSettings,
                                    values: { 'openid_connect' => { 'no_new_user_creation' => true } }))
      request.env['omniauth.auth'] = auth_hash(provider: 'openid_connect')

      get :openid_connect

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include(I18n.t('devise.openid_connect.errors.no_local_user_map'))
    end

    it 'reports missing email' do
      allow(ApplicationSettings).to receive(:instance)
        .and_return(instance_double(ApplicationSettings, values: { 'openid_connect' => { 'enabled' => true } }))
      request.env['omniauth.auth'] = auth_hash(provider: 'openid_connect', email: nil)

      get :openid_connect

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include('Email')
    end
  end

  describe 'GET saml' do
    include_examples 'an SSO callback', :saml, 'saml', 'saml'

    it 'reports missing email' do
      allow(ApplicationSettings).to receive(:instance)
        .and_return(instance_double(ApplicationSettings, values: { 'saml' => { 'enabled' => true } }))
      request.env['omniauth.auth'] = auth_hash(provider: 'saml', email: nil)

      get :saml

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include('Email')
    end

    it 'returns error when no local user can be mapped' do
      allow(ApplicationSettings).to receive(:instance)
        .and_return(instance_double(ApplicationSettings, values: { 'saml' => { 'no_new_user_creation' => true } }))
      request.env['omniauth.auth'] = auth_hash(provider: 'saml')

      get :saml

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include(I18n.t('devise.saml.errors.no_local_user_map'))
    end
  end

  describe 'GET customazureactivedirectory' do
    let(:azure_conf) do
      { 'enable_sign_in' => true, 'app_id' => 'azure-app', 'provider_name' => 'customazureactivedirectory' }
    end
    let(:settings_values) { { 'azure_ad_apps' => [azure_conf] } }
    let(:extra) { { raw_info: { aud: 'azure-app', sub: 'azure-sub' } } }

    it 'creates a new user using the matching app config' do
      request.env['omniauth.auth'] = auth_hash(provider: 'azure', uid: nil, extra: extra)

      expect { get :customazureactivedirectory }.to change(User, :count).by(1)

      user = User.find_by(email: 'sso.user@example.com')
      expect(user.user_identities.pluck(:provider, :uid)).to eq [%w(customazureactivedirectory azure-sub)]
      expect(controller.current_user).to eq user
    end

    it 'signs in a user with a matching identity' do
      user = create :user, confirmed_at: Time.zone.now
      create :user_identity, user: user, provider: 'customazureactivedirectory', uid: 'azure-sub'
      request.env['omniauth.auth'] = auth_hash(provider: 'azure', uid: nil, extra: extra)

      get :customazureactivedirectory

      expect(controller.current_user).to eq user
    end

    it 'links an existing user when auto linking is enabled' do
      azure_conf.merge!('no_new_user_creation' => true, 'auto_link_on_sign_in' => true)
      user = create :user, email: 'sso.user@example.com'
      request.env['omniauth.auth'] = auth_hash(provider: 'azure', uid: 'azure-uid', extra: extra)

      get :customazureactivedirectory

      expect(user.user_identities.pluck(:uid)).to eq ['azure-uid']
      expect(controller.current_user).to eq user
    end

    it 'redirects with error when no local user can be mapped' do
      azure_conf['no_new_user_creation'] = true
      request.env['omniauth.auth'] = auth_hash(provider: 'azure', uid: 'azure-uid', extra: extra)

      get :customazureactivedirectory

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include(I18n.t('devise.azure.errors.no_local_user_map'))
    end

    it 'reports missing email' do
      request.env['omniauth.auth'] = auth_hash(provider: 'azure', uid: 'azure-uid', email: nil, extra: extra)

      get :customazureactivedirectory

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include('Email')
    end

    it 'redirects with generic error when no app config matches' do
      request.env['omniauth.auth'] = auth_hash(provider: 'azure', extra: { raw_info: { aud: 'unknown' } })

      expect { get :customazureactivedirectory }.not_to change(User, :count)

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include(I18n.t('devise.azure.errors.generic'))
    end
  end

  describe 'GET linkedin' do
    let(:linkedin_auth) do
      OmniAuth::AuthHash.new(
        provider: 'linkedin', uid: 'li-1',
        info: { 'email' => 'linked.in@example.com', 'first_name' => 'Linked', 'last_name' => 'In' }
      )
    end

    before do
      allow(Rails.configuration.x).to receive(:enable_user_registration).and_return(true)
      allow(Rails.configuration.x).to receive(:linkedin_signin_enabled).and_return(true)
      request.env['omniauth.auth'] = linkedin_auth
    end

    it 'renders 403 when linkedin sign in is disabled' do
      allow(Rails.configuration.x).to receive(:linkedin_signin_enabled).and_return(false)

      get :linkedin

      expect(response).to have_http_status(:forbidden)
    end

    it 'creates a new user and redirects to complete sign up' do
      expect { get :linkedin }.to change(User, :count).by(1)

      user = User.find_by(email: 'linked.in@example.com')
      expect(user.initials).to eq 'LI'
      expect(user.confirmed_at).to be_present
      expect(user.user_identities.pluck(:uid)).to eq ['li-1']
      expect(response).to redirect_to(users_sign_up_provider_path)
    end

    it 'signs in an existing user with a team' do
      team = create :team
      user = create :user, current_team_id: team.id, confirmed_at: Time.zone.now
      create :user_identity, user: user, provider: 'linkedin', uid: 'li-1'

      get :linkedin

      expect(controller.current_user).to eq user
      expect(flash[:notice]).to be_present
    end

    it 'asks existing user without team to complete sign up' do
      user = create :user, confirmed_at: Time.zone.now
      create :user_identity, user: user, provider: 'linkedin', uid: 'li-1'

      get :linkedin

      expect(response).to redirect_to(users_sign_up_provider_path)
      expect(flash[:alert]).to include(I18n.t('devise.linkedin.complete_sign_up'))
    end

    it 'rejects sign up when email is taken' do
      create :user, email: 'linked.in@example.com'

      expect { get :linkedin }.not_to change(User, :count)

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include('linked.in@example.com')
    end

    it 'redirects with failure when the user cannot be saved' do
      linkedin_auth.info.first_name = ''
      linkedin_auth.info.last_name = 'x' * 300

      expect { get :linkedin }.not_to change(User, :count)

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include(I18n.t('devise.linkedin.failed_to_save'))
    end
  end
end
