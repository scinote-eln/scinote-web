class Users::SessionsController < Devise::SessionsController
  # before_filter :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

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

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.for(:sign_in) << :attribute
  end
end
