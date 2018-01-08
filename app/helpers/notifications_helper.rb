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

  def generate_notification(user, target_user, team, role, project)
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
    elsif project
      title = I18n.t('activities.unassign_user_from_project',
                     unassigned_user: target_user.full_name,
                     project: project.name,
                     unassigned_by_user: user.full_name)
      message = "#{I18n.t('search.index.project')} #{@project.name}"
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
