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
        user = User.find(current_user.id)
        is_saved = user.update(user_params)

        if is_saved
          bypass_sign_in(user)
          res = "success"
        else
          res = "could not change password"
        end

        respond_to do |format|
          if is_saved
            format.json { render json: { msg: res} }
          else
            format.json { render json: { msg: res}, status: 422 }
          end
        end
      end

      def change_assignements_notification
        change_notification(:assignments_notification, params)
      end

      def change_assignements_notification_email
        change_notification(:assignments_notification_email, params)
      end

      def change_recent_notification
        change_notification(:recent_notification, params)
      end

      def change_recent_notification_email
        change_notification(:recent_notification_email, params)
      end

      def change_system_notification_email
        change_notification(:system_message_notification_email, params)
      end

      def change_timezone
        user = current_user
        errors = { timezone_errors: [] }
        user.time_zone = params['timezone']

        timezone = if user.save
                     user.time_zone
                   else
                     msg = 'You need to select valid TimeZone.'
                     user.reload.time_zone
                     errors[:timezone_errors] << msg
                   end

        respond_to do |format|
          format.json { render json: { timezone: timezone, errors: errors}}
        end
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
          resp = { email: saved_email || current_email, errors: errors }
          format.json { render json: resp }
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
          resp = { fullName: saved_name, errors: user.errors.messages }
          format.json { render json: resp }
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

      private

      def user_params
        params.require(:user).permit(:password)
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
