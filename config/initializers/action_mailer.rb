# frozen_string_literal: true

if ENV['SMTP_USE_AWS_SES'] == 'true'
  options = {}
  options[:region] = ENV['AWS_SES_REGION'] if ENV['AWS_SES_REGION'].present?
  ActionMailer::Base.add_delivery_method :ses, Aws::ActionMailer::SES::Mailer, **options
end
