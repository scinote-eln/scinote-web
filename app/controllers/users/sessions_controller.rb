# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout :session_layout
  after_action :after_sign_in, only: %i(create authenticate_with_two_factor)
  before_action :remove_authenticate_mesasge_if_root_path, only: :new

  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_to new_user_session_path
  end

  # GET /resource/sign_in
  def new
    @simple_sign_in = params[:simple_sign_in] == 'true'
    # If user was redirected here from OAuth's authorize/new page (Doorkeeper
    # endpoint for authorizing an OAuth client), 3rd party sign-in buttons
    # (e.g. LinkedIn) should be hidden. See config/initializers/devise.rb.
    @oauth_authorize = session['oauth_authorize'] == true
    super
  end

  # POST /resource/sign_in
  def create
    super do |user|
      if redirect_to_two_factor_auth?(user)
        initial_page = stored_location_for(:user)
        sign_out
        session[:otp_user_id] = user.id
        store_location_for(:user, initial_page)
        redirect_to users_two_factor_auth_path
        return
      end
    end
    generate_templates_project
  end

  def two_factor_recovery
    unless session[:otp_user_id]
      redirect_to new_user_session_path
    end
  end

  def two_factor_auth
    @initial_page = stored_location_for(:user)
  end

  def after_sign_in
    flash[:system_notification_modal] = true
  end

  def authenticate_with_two_factor
    user = User.find_by(id: session[:otp_user_id])

    unless user
      flash[:alert] = t('devise.sessions.2fa.no_user_error')
      redirect_to root_path && return
    end

    if user.valid_otp?(params[:otp])
      session.delete(:otp_user_id)

      sign_in(user)
      generate_templates_project
      flash[:notice] = t('devise.sessions.signed_in')
      redirect_to params[:initial_page] || root_path
    else
      flash.now[:alert] = t('devise.sessions.2fa.error_message')
      render :two_factor_auth
    end
  end

  def authenticate_with_recovery_code
    user = User.find_by(id: session[:otp_user_id])

    unless user
      flash[:alert] = t('devise.sessions.2fa.no_user_error')
      redirect_to root_path && return
    end

    session.delete(:otp_user_id)
    if user.recover_2fa!(params[:recovery_code])
      sign_in(user)
      generate_templates_project
      flash[:notice] = t('devise.sessions.signed_in')
      redirect_to root_path
    else
      flash[:alert] = t("devise.sessions.2fa_recovery.not_correct_code")
      redirect_to new_user_session_path
    end

  end

  private

  def remove_authenticate_mesasge_if_root_path
    if session[:user_return_to] == root_path && flash[:alert] == I18n.t('devise.failure.unauthenticated')
      flash[:alert] = nil
    end
  end

  def generate_templates_project
    # Schedule templates creation for user
    TemplatesService.new.schedule_creation_for_user(current_user)
  rescue StandardError => e
    Rails.logger.fatal("User ID #{current_user.id}: Error creating inital projects on sign_in: #{e.message}")
  end

  def session_layout
    if @simple_sign_in
      'sign_in_halt'
    else
      'layouts/main'
    end
  end

  def bypass_two_factor_auth?
    false
  end

  def redirect_to_two_factor_auth?(user)
    user.two_factor_auth_enabled? && !bypass_two_factor_auth?
  end
end
