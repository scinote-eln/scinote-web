module ClientApi
  module Users
    class UsersController < ApplicationController

      def current_user_info
        respond_to do |format|
          format.json do
            render template: '/client_api/users/show',
                  status: :ok,
                  locals: { user: current_user }
          end
        end
      end

      def change_password
        binding.pry
      end

      def change_email
        user = current_user
        user.email = params['email']
        saved_email = if user.save
          user.email
        else
          user.reload.email
        end

        respond_to do |format|
          format.json { render json: { email: saved_email } }
        end
      end

      def change_full_name
        user = current_user
        user.name = params['fullName']
        saved_name = if user.save
          user.name
        else
          user.reload.name
        end

        respond_to do |format|
          format.json { render json: { fullName: saved_name } }
        end
      end

      def change_initials
        user = current_user
        user.initials = params['initials']
        saved_initials = if user.save
          user.initials
        else
          user.reload.initials
        end

        respond_to do |format|
          format.json { render json: { initials: saved_initials } }
        end
      end
    end
  end
end
