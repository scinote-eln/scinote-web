module NotificationsHelper
  def send_email_notification(user, notification)
    AppMailer.delay.notification(user, notification)
  end

  # generate assignment notification
  def generate_notification(user, target_user, team, role)
    if team
      title = I18n.t('notifications.unassign_user_from_team',
                     unassigned_user: target_user.name,
                     team: team.name,
                     unassigned_by_user: user.name)
      title = I18n.t('notifications.assign_user_to_team',
                     assigned_user: target_user.name,
                     role: role,
                     team: team.name,
                     assigned_by_user: user.name) if role
      message = "#{I18n.t('search.index.team')} #{team.name}"
    end

    notification = Notification.create(
      type_of: :assignment,
      title: sanitize_input(title),
      message: sanitize_input(message)
    )

    if target_user.assignments_notification
      UserNotification.create(notification: notification, user: target_user)
    end
  end
end
