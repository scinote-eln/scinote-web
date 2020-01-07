# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout :session_layout

  # before_filter :configure_sign_in_params, only: [:create]
  after_action :after_sign_in, only: :create

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
    super

    # Schedule templates creation for user
    TemplatesService.new.schedule_creation_for_user(current_user)

    # Schedule demo project creation for user
    current_user.created_teams.each do |team|
      FirstTimeDataGenerator.delay(
        queue: :new_demo_project,
        priority: 10
      ).seed_demo_data_with_id(current_user.id, team.id)
    end
  rescue StandardError => e
    Rails.logger.fatal(
      "User ID #{current_user.id}: Error creating inital projects on sign_in: "\
      "#{e.message}"
    )
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # Singing in with authentication token (needed when signing in automatically
  # from another website). NOTE: For some reason URL needs to end with '/'.
  def auth_token_create
    user = User.find_by_email(params[:user_email])
    user_token = params[:user_token]
    # Remove trailing slash if present
    user_token.chop! if !user_token.nil? && user_token.end_with?('/')

    if user && user.authentication_token == user_token
      sign_in(:user, user)
      # This will cause new token to be generated
      user.update(authentication_token: nil)
      redirect_url = root_path
    else
      flash[:error] = t('devise.sessions.auth_token_create.wrong_credentials')
      redirect_url = new_user_session_path
    end

    respond_to do |format|
      format.html do
        redirect_to redirect_url
      end
    end
  end

  def after_sign_in
    flash[:system_notification_modal] = true
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.for(:sign_in) << :attribute
  end

  private

  def session_layout
    if @simple_sign_in
      'sign_in_halt'
    else
      'layouts/main'
    end
  end
end
