class UserNotification < ActiveRecord::Base
  include NotificationsHelper

  belongs_to :user
  belongs_to :notification

  after_save :send_email

  def self.last_notifications(user, last_notification_id = nil, per_page = 10)
    last_notification_id = 999999999999999999999999 if last_notification_id < 1
    Notification.joins(:user_notifications)
                .where('user_notifications.user_id = ?', user.id)
                .where('notifications.id < ?', last_notification_id)
                .order(created_at: :DESC)
                .limit(per_page)
  end

  def self.recent_notifications(user)
    Notification.joins(:user_notifications)
                .where('user_notifications.user_id = ?', user.id)
                .order(created_at: :DESC)
                .limit(10)
  end

  def self.unseen_notification_count(user)
    where('user_id = ? AND checked = false', user.id).count
  end

  def self.seen_by_user(user)
    where(user: user).where(checked: false).update_all(checked: true)
  end

  def send_email
    case notification.type_of
    when 'system_message'
      send_email_notification(
        user,
        notification
      ) if user.system_message_notification_email
    when 'assignment'
      send_email_notification(
        user,
        notification
      ) if user.assignments_notification_email
    when 'recent_changes'
      send_email_notification(
        user,
        notification
      ) if user.recent_notification_email
    end
  end
end
