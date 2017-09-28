module ClientApi
  class UserService < BaseService
    def update_user!
      error = I18n.t('client_api.user.passwords_dont_match')
      raise CustomUserError, error unless check_password_confirmation
      @params.delete(:current_password) # removes unneeded element
      @current_user.update(@params)
    end

    private

    def check_password_confirmation
      return true unless @params[:email] || @params[:password]
      error = I18n.t('client_api.user.blank_password_error')
      password_confirmation = @params[:current_password]
      raise CustomUserError, error unless password_confirmation
      @current_user.valid_password? password_confirmation
    end
  end
  CustomUserError = Class.new(StandardError)
end
