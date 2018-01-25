module ClientApi
  class NotificationsController < ApplicationController
    def recent_notifications
      respond_to do |format|
        format.json do
          render template: '/client_api/notifications/index',
                 status: :ok,
                 locals: {
                   notifications:
                    UserNotification.recent_notifications(current_user)
                 }
        end
      end
      # clean the unseen notifications
      UserNotification.seen_by_user(current_user)
    end

    def unread_notifications_count
      respond_to do |format|
        format.json do
          render json: {
            count: UserNotification.unseen_notification_count(current_user)
          }, status: :ok
        end
      end
    end
  end
end
