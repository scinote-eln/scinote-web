# frozen_string_literal: true

ActiveSupport::Reloader.to_prepare do
  settings = ApplicationSettings.instance
  provider_conf = settings.values['okta']
  if provider_conf.blank? && %w(OKTA_CLIENT_ID OKTA_CLIENT_SECRET OKTA_DOMAIN).all? { |v| ENV.fetch(v, nil).present? }
    provider_conf = {}
    provider_conf['client_id'] = ENV.fetch('OKTA_CLIENT_ID')
    provider_conf['client_secret'] = ENV.fetch('OKTA_CLIENT_SECRET')
    provider_conf['domain'] = ENV.fetch('OKTA_DOMAIN')
    provider_conf['auth_server_id'] = ENV['OKTA_AUTH_SERVER_ID'] if ENV['OKTA_AUTH_SERVER_ID'].present?
    provider_conf['audience'] = ENV['OKTA_AUDIENCE'] if ENV['OKTA_AUDIENCE'].present?
    settings.values['okta'] = provider_conf
    settings.save!
  end
rescue ActiveRecord::ActiveRecordError, PG::ConnectionBad
  Rails.logger.info('Not connected to database, skipping additional Okta configuration')
end
