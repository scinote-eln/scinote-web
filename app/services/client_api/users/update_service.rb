module ClientApi
  module Users
    class UpdateService < BaseService
      attr_accessor :user

      def execute
        @user = @current_user

        if current_password_valid? &&
           password_confirmation_valid? &&
           @user.update(@params.except(:current_password))
          success
        else
          error(@user.errors.full_messages.uniq.join('. '))
        end
      end

      private

      def current_password_valid?
        # Only check for current_password when updating
        # email or password
        return true unless @params[:email] || @params[:password]

        if @user.valid_password?(@params[:current_password])
          return true
        else
          @user.errors.add(
            :current_password,
            I18n.t('client_api.user.current_password_invalid')
          )
          return false
        end
      end

      def password_confirmation_valid?
        # Only check for password_confirmation when
        # updating password
        return true unless @params[:password]

        if @params[:password] == @params[:password_confirmation]
          return true
        else
          @user.errors.add(
            :password_confirmation,
            I18n.t('client_api.user.password_confirmation_not_match')
          )
          return false
        end
      end
    end
  end
end
