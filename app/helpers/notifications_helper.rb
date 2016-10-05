module NotificationsHelper
  def create_system_notification(title, message)
    notification = Notification.new
    notification.title = title
    notification.message = message
    notification.type_of = :system_message
    notification.transaction do
      User.where.not(confirmed_at: nil).find_each do |u|
        UserNotification
          .new(user: u, notification: notification, checked: false)
          .save!
      end
      notification.save!
    end
  end

  def send_email_notification(user, notification)
    AppMailer.delay.notification(user, notification)
  end
end
