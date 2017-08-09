module ClientApi
  class NotificationsController < ApplicationController
    before_action :last_notifications, only: :recent_notifications

    def recent_notifications
      respond_to do |format|
        format.json do
          render template: '/client_api/notifications/index',
                 status: :ok,
                 locals: { notifications: @recent_notifications }
        end
      end
    end

    private

    def last_notifications
      @recent_notifications =
        UserNotification.recent_notifications(current_user)
      UserNotification.seen_by_user(current_user)
    end
  end
end
