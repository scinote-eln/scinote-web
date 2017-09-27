module ClientApi
  module Users
    class UsersController < ApplicationController

      def preferences_info
        settings = current_user.settings
        respond_to do |format|
          format.json do
            render template: 'client_api/users/preferences',
                   status: :ok,
                   locals: {
                     timeZone: settings['time_zone'],
                     notifications: settings['notifications']
                   }
          end
        end
      end

      def profile_info
        respond_to do |format|
          format.json do
            render template: '/client_api/users/profile',
                   status: :ok,
                   locals: { user: current_user }
          end
        end
      end

      def statistics_info
        respond_to do |format|
          format.json do
            render template: '/client_api/users/statistics',
                   status: :ok,
                   locals: { user: current_user }
          end
        end
      end

      def current_user_info
        respond_to do |format|
          format.json do
            render template: '/client_api/users/show',
                   status: :ok,
                   locals: { user: current_user }
          end
        end
      end

      def update
        user_service = ClientApi::UserService.new(
          current_user: current_user,
          params: user_params
        )
        if user_service.update_user!
          bypass_sign_in(current_user)
          success_response
        else
          unsuccess_response(current_user.errors.full_messages, :unauthorized)
        end
      rescue CustomUserError => error
        unsuccess_response(error.to_s)
      end

      private

      def user_params
        params.require(:user)
              .permit(:password,
                      :initials,
                      :email,
                      :full_name,
                      :password_confirmation,
                      :current_password,
                      :avatar,
                      :assignments,
                      :time_zone)
      end

      def change_notification(dinamic_param, params)
        user = current_user
        user[dinamic_param] = params['status']
        status =
          if user.save
            user[dinamic_param]
          else
            user.reload[dinamic_param]
          end

        respond_to do |format|
          format.json { render json: { status: status } }
        end
      end

      def success_response(template = nil, locals = nil)
        respond_to do |format|
          format.json do
            if template && locals
              render template: template, status: :ok, locals: locals
            else
              render json: {}, status: :ok
            end
          end
        end
      end

      def unsuccess_response(message, status = :unprocessable_entity)
        respond_to do |format|
          format.json do
            render json: { message: message },
            status: status
          end
        end
      end
    end
  end
end
