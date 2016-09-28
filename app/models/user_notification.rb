class UserNotification < ActiveRecord::Base
  belongs_to :user
  belongs_to :notification

  def recent_notifications
  end

  def unseen_notification
  end
end
