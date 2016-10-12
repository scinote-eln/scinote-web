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
end