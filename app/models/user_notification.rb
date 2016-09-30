class UserNotification < ActiveRecord::Base
  belongs_to :user
  belongs_to :notification

  def self.recent_notifications(user)
    Notification.joins(:user_notifications)
                .where('user_notifications.user_id = ?', user.id)
                .order(created_at: :DESC)
                .limit(10)
  end

  def self.unseen_notification(user)
    where('user_id = ? AND checked = false', user.id).count
  end

  def self.create_notification(user, title, message, type)
    notification = Notification.new
    notification.transaction do
      notification.title = title
      notification.message = message
      notification.type_of = type
      notification.save!
      usernotification = UserNotification
        .new(user: user, notification: notification, checked: false)
      usernotification.save!
    end
  end
end
