module ClientApi
  class UserService < BaseService
    def update_user!
      error = I18n.t('client_api.user.passwords_dont_match')
      raise CustomUserError, error unless check_current_password
      @params.delete(:current_password) # removes unneeded element
      @current_user.update(@params)
    end

    private

    def check_current_password
      return true unless @params[:email] || @params[:password]
      pass_blank_err = I18n.t('client_api.user.blank_password_error')
      pass_match_err = I18n.t('client_api.user.passwords_dont_match')
      current_password = @params[:current_password]
      raise CustomUserError, pass_blank_err unless current_password
      raise CustomUserError, pass_match_err unless check_password_confirmation
      @current_user.valid_password? current_password
    end

    def check_password_confirmation
      return true if @params[:email]
      @params[:password] == @params[:password_confirmation]
    end
  end
  CustomUserError = Class.new(StandardError)
end
