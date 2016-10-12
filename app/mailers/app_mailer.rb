class AppMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'users/mailer'
  default from: ENV["MAIL_FROM"]
  default reply: ENV["MAIL_REPLYTO"]

  def notification(user, notification)
    @user = user
    @notification = notification
    headers = {
      to: @user.email,
      subject: I18n.t('notifications.email_title')
    }
    mail(headers)
  end
end
