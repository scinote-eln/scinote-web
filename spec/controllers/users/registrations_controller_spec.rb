# frozen_string_literal: true

require 'rails_helper'

describe Users::RegistrationsController, type: :controller do
  let(:user) { create :user, confirmed_at: Time.zone.now }
  let(:png_data_uri) do
    "data:image/jpeg;base64,#{Base64.strict_encode64(File.binread(Rails.root.join('spec/fixtures/files/apple.jpg')))}"
  end

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    @orig_x = %i(enable_user_registration new_team_on_signup enable_email_confirmations
                 enable_recaptcha linkedin_signin_enabled disable_local_passwords).index_with do |k|
      Rails.configuration.x.send(k)
    end
    Rails.configuration.x.enable_user_registration = true
    Rails.configuration.x.new_team_on_signup = false
    Rails.configuration.x.enable_email_confirmations = false
    Rails.configuration.x.enable_recaptcha = false
    allow(ApplicationSettings).to receive(:instance)
      .and_return(instance_double(ApplicationSettings, values: {}))
    # template project generation is out of scope here (and aborts the team save in the test env)
    allow_any_instance_of(Team).to receive(:generate_template_project)
  end

  after do
    @orig_x.each { |k, v| Rails.configuration.x.send("#{k}=", v) }
  end

  describe 'GET #avatar' do
    it 'redirects to the avatar url of the requested user' do
      sign_in user
      get :avatar, params: { id: user.id, style: 'thumb' }
      expect(response).to have_http_status(:redirect)
    end

    it 'falls back to current user when id is unknown' do
      sign_in user
      get :avatar, params: { id: 0, style: 'icon_small' }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'GET #new' do
    it 'renders when registration is enabled' do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it 'is forbidden when registration is disabled' do
      Rails.configuration.x.enable_user_registration = false
      get :new
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST #create' do
    let(:params) do
      { user: { full_name: 'Jane Doe', email: 'jane.doe@example.com',
                password: 'Passw0rd!Passw0rd', password_confirmation: 'Passw0rd!Passw0rd' },
        team: { name: 'Jane Team' } }
    end

    it 'is forbidden when registration is disabled' do
      Rails.configuration.x.enable_user_registration = false
      expect { post :create, params: params }.not_to change(User, :count)
      expect(response).to have_http_status(:forbidden)
    end

    context 'without new team on signup' do
      it 'creates a confirmed user with initials and redirects to sign in' do
        expect { post :create, params: params }.to change(User, :count).by(1)
        created = User.find_by(email: 'jane.doe@example.com')
        expect(created.initials).to eq 'JD'
        expect(created.confirmed_at).to be_present
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'uses placeholder initials when the name has no letters' do
        params[:user][:full_name] = '123'
        post :create, params: params
        expect(User.find_by(email: 'jane.doe@example.com').initials).to eq 'PLCH'
      end

      it 'renders new when the user is invalid' do
        params[:user][:password_confirmation] = 'other'
        expect { post :create, params: params }.not_to change(User, :count)
        expect(response).to render_template(:new)
      end
    end

    context 'with new team on signup' do
      before { Rails.configuration.x.new_team_on_signup = true }

      it 'creates user and team and assigns the current team' do
        expect { post :create, params: params }
          .to change(User, :count).by(1).and change(Team, :count).by(1)
        created = User.find_by(email: 'jane.doe@example.com')
        team = Team.find_by(name: 'Jane Team')
        expect(team.created_by).to eq created
        expect(created.current_team_id).to eq team.id
      end

      it 'renders new when the team is invalid' do
        params[:team][:name] = ''
        expect { post :create, params: params }.not_to change(User, :count)
        expect(response).to render_template(:new)
      end
    end

    context 'with recaptcha enabled' do
      before do
        Rails.configuration.x.enable_recaptcha = true
        allow(controller).to receive(:verify_recaptcha).and_return(false)
      end

      it 'renders new and creates nothing when captcha fails' do
        expect { post :create, params: params }.not_to change(User, :count)
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET #new_with_provider' do
    before { Rails.configuration.x.linkedin_signin_enabled = true }

    it 'is forbidden without a signed in user' do
      get :new_with_provider
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden when new team on signup is disabled' do
      sign_in user
      get :new_with_provider
      expect(response).to have_http_status(:forbidden)
    end

    it 'renders when new team on signup is enabled' do
      Rails.configuration.x.new_team_on_signup = true
      sign_in user
      get :new_with_provider
      expect(response).to have_http_status(:ok)
    end

    it 'is forbidden when provider sign in is disabled' do
      Rails.configuration.x.linkedin_signin_enabled = false
      sign_in user
      get :new_with_provider
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST #create_with_provider' do
    before do
      Rails.configuration.x.linkedin_signin_enabled = true
      Rails.configuration.x.new_team_on_signup = true
    end

    it 'is forbidden without a signed in user' do
      post :create_with_provider, params: { team: { name: 'T' } }
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden when new team on signup is disabled' do
      Rails.configuration.x.new_team_on_signup = false
      sign_in user
      post :create_with_provider, params: { team: { name: 'T' } }
      expect(response).to have_http_status(:forbidden)
    end

    it 'creates a team and sets it as current' do
      sign_in user
      expect { post :create_with_provider, params: { team: { name: 'Provider Team' } } }
        .to change(Team, :count).by(1)
      expect(user.reload.current_team_id).to eq Team.find_by(name: 'Provider Team').id
      expect(response).to redirect_to(root_path)
    end

    it 're-renders the form for an invalid team' do
      sign_in user
      expect { post :create_with_provider, params: { team: { name: '' } } }.not_to change(Team, :count)
      expect(response).to render_template(:new_with_provider)
    end
  end

  describe 'GET #edit' do
    it 'renders for a signed in user' do
      sign_in user
      get :edit
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PUT #update' do
    before { sign_in user }

    it 'updates simple attributes without password (json)' do
      put :update, params: { user: { full_name: 'New Name' } }, format: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.full_name).to eq 'New Name'
    end

    it 'updates simple attributes (html)' do
      put :update, params: { user: { full_name: 'Html Name' } }
      expect(response).to redirect_to(edit_user_registration_path)
      expect(user.reload.full_name).to eq 'Html Name'
    end

    it 'changes the password when current password is valid' do
      put :update, params: { user: { change_password: true, current_password: 'asdf1243',
                                     password: 'N3wPassw0rd!N3w', password_confirmation: 'N3wPassw0rd!N3w' } },
                   format: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?('N3wPassw0rd!N3w')).to be true
    end

    it 'rejects a blank new password' do
      put :update, params: { user: { change_password: true, current_password: 'asdf1243',
                                     password: '', password_confirmation: '' } },
                   format: :json
      expect(response).to have_http_status(:bad_request)
      expect(user.reload.valid_password?('asdf1243')).to be true
    end

    it 'rejects a wrong current password' do
      put :update, params: { user: { change_password: true, current_password: 'wrong',
                                     password: 'N3wPassw0rd!N3w', password_confirmation: 'N3wPassw0rd!N3w' } },
                   format: :json
      expect(response).to have_http_status(:bad_request)
    end

    it 'requires current password when changing email' do
      put :update, params: { user: { email: 'changed@example.com', current_password: 'wrong' } }, format: :json
      expect(response).to have_http_status(:bad_request)
    end

    it 'allows changing email with valid current password' do
      put :update, params: { user: { email: 'changed@example.com', current_password: 'asdf1243' } }, format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'attaches a new avatar' do
      put :update, params: { user: { change_avatar: true, avatar: png_data_uri } }, format: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.avatar).to be_attached
    end

    it 'rejects a missing avatar' do
      put :update, params: { user: { change_avatar: true } }, format: :json
      expect(response).to have_http_status(:bad_request)
    end

    context 'when SSO is enforced' do
      before do
        allow(controller).to receive(:sso_enabled?).and_return(true)
        allow(controller).to receive(:sso_provider_enabled?).and_return(true)
      end

      it 'forbids changing email' do
        put :update, params: { user: { email: 'sso@example.com', current_password: 'asdf1243' } }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'forbids changing password when local passwords are disabled' do
        Rails.configuration.x.disable_local_passwords = true
        put :update, params: { user: { change_password: true, current_password: 'asdf1243' } }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'two factor' do
    before { sign_in user }

    it 'returns a QR code and assigns an otp secret' do
      get :two_factor_qr_code
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['qr_code']).to include('<svg')
      expect(user.reload.otp_secret).to be_present
    end

    it 'enables 2FA with a valid code' do
      user.assign_2fa_token!
      code = ROTP::TOTP.new(user.otp_secret, issuer: 'sciNote').now
      post :two_factor_enable, params: { submit_code: code }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['recovery_codes']).to be_present
      expect(user.reload.two_factor_auth_enabled).to be true
    end

    it 'rejects an invalid code' do
      user.assign_2fa_token!
      post :two_factor_enable, params: { submit_code: '000000' }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.two_factor_auth_enabled).to be_falsey
    end

    it 'disables 2FA with the right password' do
      user.assign_2fa_token!
      user.enable_2fa!
      post :two_factor_disable, params: { password: 'asdf1243' }
      expect(response).to redirect_to(edit_user_registration_path)
      expect(user.reload.two_factor_auth_enabled).to be false
    end

    it 'refuses to disable 2FA with a wrong password' do
      user.assign_2fa_token!
      user.enable_2fa!
      post :two_factor_disable, params: { password: 'nope' }
      expect(response).to have_http_status(:forbidden)
      expect(user.reload.two_factor_auth_enabled).to be true
    end
  end

  describe 'api key' do
    before { sign_in user }

    it 'regenerates the api key' do
      post :regenerate_api_key
      expect(user.reload.api_key).to be_present
      expect(response).to redirect_to(edit_user_registration_path(anchor: 'api-key'))
      expect(flash[:token]).to eq user.api_key
    end

    it 'revokes the api key' do
      user.regenerate_api_key!
      post :revoke_api_key
      expect(user.reload.api_key).to be_nil
      expect(response).to redirect_to(edit_user_registration_path(anchor: 'api-key'))
    end
  end
end
