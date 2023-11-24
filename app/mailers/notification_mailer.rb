# frozen_string_literal: true

class NotificationMailer < Devise::Mailer
  helper :application, :mailer, :input_sanitize
  include Devise::Controllers::UrlHelpers
  default template_path: 'users/mailer'
  default from: ENV.fetch('MAIL_FROM')
  default reply: ENV.fetch('MAIL_REPLYTO')

  def general_notification
    @user = params[:recipient]
    @notification = params[:record].to_notification

    mail(
      to: @user.email,
      subject: I18n.t('notifications.email_title')
    )
  end
end
