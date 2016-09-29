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
end
