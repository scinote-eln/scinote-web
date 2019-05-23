class AppMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    AppMailer.confirmation_instructions(fake_user, 'faketoken', {})
  end

  def reset_password_instructions
    AppMailer.reset_password_instructions(fake_user, 'faketoken', {})
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
          'notifications.assign_user_to_team',
          assigned_user: fake_user_2.full_name,
          role: 'Administrator',
          team: fake_team.name,
          assigned_by_user: fake_user.full_name
        ),
        message: ActionController::Base.helpers.sanitize(
          "<a href='#' target='_blank'>#{fake_team.name}</a>"
        ),
        generator_user: fake_user,
        created_at: Time.now
      )
    )
  end

  def recent_changes_notification
    user = User.first
    user = fake_user if user.blank?
    AppMailer.notification(
      user,
      Notification.new(
        type_of: :recent_changes,
        title: I18n.t(
          'global_activities.activity_name.create_module',
          user: user.full_name,
          module: 'How to shred'
        ),
        message: ActionController::Base.helpers.sanitize(
          'Project: <a href="#" target="_blank">School of Rock</a>'
        ),
        generator_user: user,
        created_at: Time.now
      )
    )
  end

  # <b>DEPRECATED:</b> Please use <tt>system_notification</tt> instead.
  def system_message_notification
    AppMailer.notification(
      fake_user,
      Notification.new(
        type_of: :system_message,
        title: 'SciNote 9.1 released!',
        message: '<a href="#" target="_blank">View release notes</a>',
        created_at: Time.now
      )
    )
  end

  def delivery_notification
    AppMailer.notification(
      fake_user,
      Notification.new(
        type_of: :deliver,
        title: 'Your requested export package is ready!',
        message: '<a href="/zip_exports/download/1" target="_blank" ' \
                 'data-id="1">export_YYYY-MM-DD_HH-mm-ss.zip</a>',
        created_at: Time.now
      )
    )
  end

  def system_notification
    sn = FactoryBot.build(:system_notification)
    user = FactoryBot.build(:user)
    AppMailer.system_notification(user, sn)
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

  def fake_team
    Team.new(
      name: 'Greatest musicians of all time'
    )
  end
end
