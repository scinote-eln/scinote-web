class AppMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    AppMailer.confirmation_instructions(fake_user, "faketoken", {})
  end

  def reset_password_instructions
    AppMailer.reset_password_instructions(fake_user, "faketoken", {})
  end

  def unlock_instructions
    AppMailer.unlock_instructions(fake_user, "faketoken", {})
  end

  def invitation_instructions
    AppMailer.invitation_instructions(fake_user, "faketoken", {})
  end

  def invitation_to_organization
    AppMailer.invitation_to_organization(fake_user, fake_user_2, fake_org, {})
  end

  private

  def fake_user
    User.new(
      full_name: "Johny Cash",
      initials: "JC",
      email: "johny.cash@gmail.com",
      created_at: Time.now,
      updated_at: Time.now,
      confirmed_at: Time.now
    )
  end

  def fake_user_2
    User.new(
      full_name: "Bob Dylan",
      initials: "BD",
      email: "bob.dylan@gmail.com",
      created_at: Time.now,
      updated_at: Time.now,
      confirmed_at: Time.now
    )
  end

  def fake_org
    Organization.new(
      name: "Greatest musicians of all time"
    )
  end
end