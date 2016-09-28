class UserNotifications < ApplicationController
  def recent_notifications
    @recent_notifications = UserNorifications.recent_notifications
    @unseen_notification = UserNotifications.unseen_notification
  end
end
