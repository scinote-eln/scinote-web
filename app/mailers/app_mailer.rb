class AppMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'users/mailer'
  default from: ENV["MAIL_FROM"]
  default reply: ENV["MAIL_REPLYTO"]

  def invitation_to_organization(user, added_by, organization, opts = {})
    @user = user
    @added_by = added_by
    @org = organization
    headers = { to: @user.email, subject: (I18n.t('mailer.invitation_to_organization.subject')) }.merge(opts)
    mail(headers)
  end
end