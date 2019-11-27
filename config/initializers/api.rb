# frozen_string_literal: true

Rails.application.configure do
  config.x.core_api_sign_alg = ENV['CORE_API_SIGN_ALG'] if ENV['CORE_API_SIGN_ALG']

  config.x.core_api_token_ttl = ENV['CORE_API_TOKEN_TTL'].to_i.seconds if ENV['CORE_API_TOKEN_TTL']

  config.x.core_api_token_iss = ENV['CORE_API_TOKEN_ISS'] if ENV['CORE_API_TOKEN_ISS']

  config.x.core_api_rate_limit = ENV['CORE_API_RATE_LIMIT'] ? ENV['CORE_API_RATE_LIMIT'].to_i : 1000

  config.x.core_api_v1_enabled = true if ENV['CORE_API_V1_ENABLED']
end
