module Users
  module Settings
    module Account
      class PreferencesController < ApplicationController
        before_action :load_user, only: [
          :index,
          :update
        ]
        before_action :set_breadcrumbs_items, only: %i(index)
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

        def update_params
          params.require(:user).permit(:time_zone, :date_format, notifications_settings: {})
        end

        def read_from_params(name)
          yield(params.include?(name) ? true : false)
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
