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
  # from another website)
  def auth_token_create
    user = User.find_by_email(params[:user_email])
    if user.authentication_token == params[:user_token][0..-2]
      sign_in(:user, user)
    else
      flash[:error] = t('devise.sessions.auth_token_createwrong_credentials')
    end

    respond_to do |format|
      format.html do
        redirect_to root_path
      end
    end
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.for(:sign_in) << :attribute
  end

end
