# frozen_string_literal: true

require 'omniauth/strategies/custom_azure_active_directory'

AZURE_SETUP_PROC = lambda do |env|
  settings = ApplicationSettings.instance
  providers = settings.values['azure_ad_apps'].select { |v| v['enable_sign_in'] }
  raise StandardError, 'No Azure AD config available for sign in' if providers.blank?

  req = Rack::Request.new(env)

  if providers.size > 1
    if req.params['id_token'].present? # Callback phase
      unverified_jwt_payload, = JWT.decode(req.params['id_token'], nil, false)
      provider_conf = providers.select { |v| v['app_id'] == unverified_jwt_payload['aud'] }
    else # Authorization phase
      raise ActionController::ParameterMissing, 'Provider name is missing' if req.params['provider'].blank?

      provider_conf = providers.find { |v| v['provider_name'] == req.params['provider'] }
    end
    raise StandardError, 'No Azure AD config available for sign in' if provider_conf.blank?
  end

  provider_conf ||= providers.first
  env['omniauth.strategy'].options[:client_id] = provider_conf['app_id']
  env['omniauth.strategy'].options[:client_secret] = provider_conf['client_secret']
  env['omniauth.strategy'].options[:tenant_id] = provider_conf['tenant_id']
  env['omniauth.strategy'].options[:sign_in_policy] = provider_conf['sign_in_policy']
  env['omniauth.strategy'].options[:name] = 'customazureactivedirectory'
  env['omniauth.strategy'].options[:conf_url] = provider_conf['conf_url']
  conf_uri = URI.parse(provider_conf['conf_url'])
  env['omniauth.strategy'].options[:base_azure_url] = "#{conf_uri.scheme || 'https'}://#{conf_uri.host}"
end

OKTA_SETUP_PROC = lambda do |env|
  settings = ApplicationSettings.instance
  provider_conf = settings.values['okta']
  raise StandardError, 'No Okta config available for sign in' if provider_conf.blank?

  oauth2_base_url =
    if provider_conf['auth_server_id'].blank?
      "https://#{provider_conf['domain']}/oauth2"
    else
      "https://#{provider_conf['domain']}/oauth2/#{provider_conf['auth_server_id']}"
    end

  client_options = {
    site: "https://#{provider_conf['domain']}",
    authorize_url: "#{oauth2_base_url}/v1/authorize",
    token_url: "#{oauth2_base_url}/v1/token",
    user_info_url: "#{oauth2_base_url}/v1/userinfo"
  }
  client_options[:audience] = provider_conf['audience'] if provider_conf['audience'].present?
  if provider_conf['auth_server_id'].present?
    client_options[:authorization_server] = provider_conf['auth_server_id']
    client_options[:use_org_auth_server] = false
  else
    client_options[:use_org_auth_server] = true
  end

  env['omniauth.strategy'].options[:client_id] = provider_conf['client_id']
  env['omniauth.strategy'].options[:client_secret] = provider_conf['client_secret']
  env['omniauth.strategy'].options[:client_options] = client_options
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider OmniAuth::Strategies::CustomAzureActiveDirectory, setup: AZURE_SETUP_PROC
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider OmniAuth::Strategies::Okta, setup: OKTA_SETUP_PROC
end

OmniAuth.config.logger = Rails.logger
