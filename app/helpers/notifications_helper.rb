module NotificationsHelper

  def create_system_notification(title, message)
    users = User.where.not(confirmed_at: nil)
    users.each do |u|
      UserNotification.create_notification(u, title, message, :system_message)
    end
  end

end
