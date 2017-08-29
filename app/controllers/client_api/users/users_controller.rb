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
        user = current_user
        user.password = params['passwrd']
        user.save
        ""
      end

      def change_email
        user = current_user
        current_email = current_user.email
        errors = { current_password_email_field: []} 

        if user.valid_password? params['passwrd']
          user.email = params['email']
          saved_email = if user.save
            user.email
          else
            user.reload.email
          end
        else
         errors[:current_password_email_field] << 'Wrong password.'
        end

        respond_to do |format|
          format.json { render json: { email: saved_email || current_email, errors: errors } }
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
          format.json { render json: { fullName: saved_name, errors: user.errors.messages } }
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
