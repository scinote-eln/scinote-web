class AppMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    AppMailer.confirmation_instructions(fake_user, 'faketoken', {})
  end

  def reset_password_instructions
    AppMailer.reset_password_instructions(fake_user, 'faketoken', {})
  end

  def unlock_instructions
    AppMailer.unlock_instructions(fake_user, 'faketoken', {})
  end

  def invitation_instructions
    AppMailer.invitation_instructions(fake_user, 'faketoken', {})
  end

  def assignment_notification
    AppMailer.notification(
      fake_user,
      Notification.new(
        type_of: :assignment,
        title: I18n.t(
          'notifications.assign_user_to_organization',
          assigned_user: fake_user_2.full_name,
          role: 'Administrator',
          organization: fake_org.name,
          assigned_by_user: fake_user.full_name
        ),
        message: ActionController::Base.helpers.sanitize(
          "<a href='#' target='_blank'>#{fake_org.name}</a>"
        )
      )
    )
  end

  def recent_changes_notification
    AppMailer.notification(
      fake_user,
      Notification.new(
        type_of: :recent_changes,
        title: I18n.t(
          'activities.create_module',
          user: fake_user.full_name,
          module: 'How to shred'
        ),
        message: ActionController::Base.helpers.sanitize(
          '<a href="#" target="_blank">School of Rock</a>'
        )
      )
    )
  end

  def system_message_notification
    AppMailer.notification(
      fake_user,
      Notification.new(
        type_of: :system_message,
        title: 'sciNote 9.1 released!',
        message: '<a href="#" target="_blank">View release notes</a>'
      )
    )
  end

  private

  def fake_user
    User.new(
      full_name: 'Johny Cash',
      initials: 'JC',
      email: 'johny.cash@gmail.com',
      created_at: Time.now,
      updated_at: Time.now,
      confirmed_at: Time.now
    )
  end

  def fake_user_2
    User.new(
      full_name: 'Bob Dylan',
      initials: 'BD',
      email: 'bob.dylan@gmail.com',
      created_at: Time.now,
      updated_at: Time.now,
      confirmed_at: Time.now
    )
  end

  def fake_org
    Organization.new(
      name: 'Greatest musicians of all time'
    )
  end
end
