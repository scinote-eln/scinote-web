class UserNotificationsController < ApplicationController
  def recent_notifications
    @recent_notifications = UserNotification.recent_notifications(current_user)

    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'recent_notifications.html.erb'
          )
        }
      end
    end
    mark_seen_notification @recent_notifications
  end

  def unseen_notification
    @number = UserNotification.unseen_notification_count(current_user)

    respond_to do |format|
      format.json do
        render json: {
          notificationNmber: @number
        }
      end
    end
  end

  private

  def mark_seen_notification(notifications)
    notifications.each do |notification|
      notification.seen_by_user(current_user)
    end
  end
end
