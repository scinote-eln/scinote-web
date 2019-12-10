# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    include UsersGenerator

    skip_before_action :verify_authenticity_token
    before_action :sign_up_with_provider_enabled?,
                  only: :linkedin

    # You should configure your model like this:
    # devise :omniauthable, omniauth_providers: [:twitter]

    # You should also create an action method in this controller like this:
    # def twitter
    # end

    def customazureactivedirectory
      auth = request.env['omniauth.auth']
      provider_id = auth.dig(:extra, :raw_info, :id_token_claims, :aud)
      provider_conf = Rails.configuration.x.azure_ad_apps[provider_id]
      raise StandardError, 'No matching Azure AD provider config found' if provider_conf.empty?

      auth.provider = provider_conf[:provider]

      return redirect_to connected_accounts_path if current_user

      email = auth.info.email
      email ||= auth.dig(:extra, :raw_info, :id_token_claims, :emails)&.first
      user = User.from_omniauth(auth)
      if user
        # User found in database so just sign in him
        sign_in_and_redirect(user)
      elsif email.present?
        user = User.find_by(email: email)

        if user.blank?
          # Create new user and identity
          User.create_from_omniauth!(auth)
          sign_in_and_redirect(user)
        elsif provider_conf[:auto_link_on_sign_in]
          # Link to existing local account
          user.user_identities.create!(provider: auth.provider, uid: auth.uid)
          sign_in_and_redirect(user)
        else
          # Cannot do anything with it, so just return an error
          error_message = I18n.t('devise.azure.errors.no_local_user_map')
          redirect_to after_omniauth_failure_path_for(resource_name)
        end
      end
    rescue StandardError => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      error_message = I18n.t('devise.azure.errors.failed_to_save') if e.is_a?(ActiveRecord::RecordInvalid)
      error_message ||= I18n.t('devise.azure.errors.generic')
      redirect_to after_omniauth_failure_path_for(resource_name)
    ensure
      if error_message
        set_flash_message(:alert, :failure, kind: I18n.t('devise.azure.provider_name'), reason: error_message)
      else
        set_flash_message(:notice, :success, kind: I18n.t('devise.azure.provider_name'))
      end
    end

    def linkedin
      auth_hash = request.env['omniauth.auth']

      @user = User.from_omniauth(auth_hash)
      if @user && @user.current_team_id?
        # User already exists and has been signed up with LinkedIn; just sign in
        set_flash_message(:notice,
                          :success,
                          kind: I18n.t('devise.linkedin.provider_name'))
        sign_in_and_redirect @user
      elsif @user
        # User already exists and has started sign up with LinkedIn;
        # but doesn't have team (needs to complete sign up - agrees to TOS)
        set_flash_message(:alert,
                          :failure,
                          kind: I18n.t('devise.linkedin.provider_name'),
                          reason: I18n.t('devise.linkedin.complete_sign_up'))
        redirect_to users_sign_up_provider_path(user: @user)
      elsif User.find_by_email(auth_hash['info']['email'])
        # email is already taken, so sign up with Linked in is not allowed
        set_flash_message(:alert,
                          :failure,
                          kind: I18n.t('devise.linkedin.provider_name'),
                          reason: I18n.t('devise.linkedin.email_already_taken',
                                         email: auth_hash['info']['email']))
        redirect_to after_omniauth_failure_path_for(resource_name)
      else
        # Create new user and identity; and redirect to complete sign up form
        full_name = "#{auth_hash['info']['first_name']} #{auth_hash['info']['last_name']}"
        @user = User.new(
          full_name: full_name,
          initials: generate_initials(full_name),
          email: auth_hash['info']['email'],
          password: generate_user_password
        )
        if auth_hash['info']['picture_url']
          avatar = URI.open(auth_hash['info']['picture_url'])
          @user.avatar.attach(io: avatar, filename: 'linkedin_avatar.jpg')
        end
        user_identity = UserIdentity.new(user: @user,
                                         provider: auth_hash['provider'],
                                         uid: auth_hash['uid'])
        unless @user.save && user_identity.save
          set_flash_message(:alert,
                            :failure,
                            kind: I18n.t('devise.linkedin.provider_name'),
                            reason: I18n.t('devise.linkedin.failed_to_save'))
          redirect_to after_omniauth_failure_path_for(resource_name) and return
        end
        # Confirm user
        @user.update_column(:confirmed_at, @user.created_at)
        redirect_to users_sign_up_provider_path(user: @user)
      end
    end

    # More info at:
    # https://github.com/plataformatec/devise#omniauth

    # GET|POST /resource/auth/twitter
    # def passthru
    #   super
    # end

    # GET|POST /users/auth/twitter/callback
    # def failure
    #   super
    # end

    # protected

    # The path used when OmniAuth fails
    # def after_omniauth_failure_path_for(scope)
    #   super(scope)
    # end

    private

    def sign_up_with_provider_enabled?
      render_403 unless Rails.configuration.x.enable_user_registration
      render_403 unless Rails.configuration.x.linkedin_signin_enabled
    end

    def generate_initials(full_name)
      initials = full_name.titleize.scan(/[A-Z]+/).join
      initials = initials.strip.empty? ? 'PLCH' : initials[0..3]
      initials
    end
  end
end
