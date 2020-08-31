# frozen_string_literal: true

require 'omniauth/strategies/custom_azure_active_directory'

SETUP_PROC = lambda do |env|
  providers = Rails.configuration.x.azure_ad_apps.select { |_, v| v[:enable_sign_in] == true }
  raise StandardError, 'No Azure AD config available for sign in' if providers.empty?

  req = Rack::Request.new(env)

  if providers.size > 1
    if req.params['id_token'].present? # Callback phase
      unverified_jwt_payload, = JWT.decode(req.params['id_token'], nil, false)
      raise StandardError, 'No Azure AD config available for sign in' if providers[unverified_jwt_payload['aud']].blank?

      provider_id = unverified_jwt_payload['aud']
    else # Authorization phase
      raise ActionController::ParameterMissing, 'Provider name is missing' if req.params['provider'].blank?

      provider_id = providers.select { |_, v| v[:provider] == req.params['provider'] }.keys.first
      raise StandardError, 'No Azure AD config available for sign in' if provider_id.blank?
    end
  end

  provider_id ||= providers.keys.first
  provider_conf = providers[provider_id]

  env['omniauth.strategy'].options[:client_id] = provider_id
  env['omniauth.strategy'].options[:openid_config_url] = provider_conf[:conf_url]
  env['omniauth.strategy'].options[:sign_in_policy] = provider_conf[:sign_in_policy]
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider OmniAuth::Strategies::CustomAzureActiveDirectory, setup: SETUP_PROC
end

OmniAuth.config.logger = Rails.logger
