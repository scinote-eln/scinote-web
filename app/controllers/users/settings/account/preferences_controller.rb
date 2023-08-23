module Users
  module Settings
    module Account
      class PreferencesController < ApplicationController
        before_action :load_user, only: [
          :index,
          :update,
          :update_togglable_settings
        ]
        layout 'fluid'

        def index
        end

        def update
          if @user.update(update_params)
            render json: { status: :ok }
          else
            render json: @user.errors, status: :unprocessable_entity
          end
        end

        def update_togglable_settings
          read_from_params(:assignments_notification) do |val|
            @user.assignments_notification = val
          end
          read_from_params(:recent_notification) do |val|
            @user.recent_notification = val
          end
          read_from_params(:recent_notification_email) do |val|
            @user.recent_email_notification = val
          end
          read_from_params(:assignments_notification_email) do |val|
            @user.assignments_email_notification = val
          end
          read_from_params(:system_message_notification_email) do |val|
            @user.system_message_email_notification = val
          end
          if @user.save
            render json: {
              status: :ok
            }
          else
            render json: {
              status: :unprocessable_entity
            }
          end
        end

        private

        def load_user
          @user = current_user
        end

        def update_params
          params.require(:user).permit(:time_zone, :date_format)
        end

        def read_from_params(name)
          yield(params.include?(name) ? true : false)
        end
      end
    end
  end
end
