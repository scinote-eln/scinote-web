# frozen_string_literal: true

module NotificationsHelper
  def send_email_notification(user, notification)
    AppMailer.delay.notification(user.id, notification)
  end

  # generate assignment notification
  def generate_notification(user, target_user, team, role)
    if team
      title = I18n.t('notifications.unassign_user_from_team',
                     unassigned_user: target_user.name,
                     team: team.name,
                     unassigned_by_user: user.name)
      if role
        title = I18n.t('notifications.assign_user_to_team',
                       assigned_user: target_user.name,
                       role: role,
                       team: team.name,
                       assigned_by_user: user.name)
      end
    end

    GeneralNotification.send_notifications(
      {
        type: role ? :invite_user_to_team : :remove_user_from_team,
        title: sanitize_input(title),
        subject_id: team.id,
        subject_class: team.class.name,
        subject_name: team.respond_to?(:name) && team.name,
        user: target_user
      }
    )
  end
end
