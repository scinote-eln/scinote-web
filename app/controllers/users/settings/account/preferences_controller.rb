module Users
  module Settings
    module Account
      class PreferencesController < ApplicationController
        before_action :load_user, only: [
          :index,
          :update
        ]
        before_action :set_breadcrumbs_items, only: %i(index)
        before_action :check_time_zone_permissions, only: :update
        before_action :check_date_format_permissions, only: :update
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

        private

        def load_user
          @user = current_user
        end

        def check_time_zone_permissions
          render_403 if update_params.include?(:time_zone) && can_set_time_zone?
        end

        def check_date_format_permissions
          render_403 if update_params.include?(:date_format) && can_set_date_format?
        end

        def update_params
          params.require(:user).permit(:time_zone, :date_format, notifications_settings: {})
        end

        def set_breadcrumbs_items
          @breadcrumbs_items = [{
            label: t('notifications.breadcrumb'),
            url: preferences_path
          }]

          @breadcrumbs_items
        end
      end
    end
  end
end
