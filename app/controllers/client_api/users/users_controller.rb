module ClientApi
  module Users
    class UsersController < ApplicationController

      def preferences_info
        respond_to do |format|
          format.json do
            render template: 'client_api/users/preferences',
                   status: :ok,
                   locals: { user: current_user}
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
        binding.pry
        respond_to do |format|
          if current_user.update(user_params)
            sign_in(current_user, bypass: true)
            format.json { render json: {}, status: :ok }
          else
            format.json {
              render json: { message: current_user.errors.full_messages },
                     status: :unprocessable_entity
                   }
          end
        end
      end

      private

      def user_params
        params.require(:user).permit(:password, :initials, :email, :full_name)
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
    end
  end
end
