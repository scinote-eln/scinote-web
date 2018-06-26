module Users
  module Settings
    module Account
      class PreferencesController < ApplicationController
        before_action :load_user, only: [
          :index,
          :update,
          :notifications_settings
        ]
        layout 'fluid'

        def index
        end

        def update
          respond_to do |format|
            if @user.update(update_params)
              flash[:notice] =
                t('users.settings.account.preferences.update_flash')
              format.json do
                flash.keep
                render json: { status: :ok }
              end
            else
              format.json do
                render json: @user.errors,
                status: :unprocessable_entity
              end
            end
          end
        end

        def notifications_settings
          @user.assignments_notification =
            params[:assignments_notification] ? true : false
          @user.recent_notification =
            params[:recent_notification] ? true : false
          @user.recent_email_notification =
            params[:recent_notification_email] ? true : false
          @user.assignments_email_notification =
            params[:assignments_notification_email] ? true : false
          @user.system_message_email_notification =
            params[:system_message_notification_email] ? true : false

          if @user.save
            respond_to do |format|
              format.json do
                render json: {
                  status: :ok
                }
              end
            end
          else
            respond_to do |format|
              format.json do
                render json: {
                  status: :unprocessable_entity
                }
              end
            end
          end
        end

        private

        def load_user
          @user = current_user
        end

        def update_params
          params.require(:user).permit(
            :time_zone
          )
        end
      end
    end
  end
end
