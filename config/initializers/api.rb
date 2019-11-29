# frozen_string_literal: true

Rails.application.configure do
  config.x.core_api_sign_alg = ENV['CORE_API_SIGN_ALG'] || 'HS256'

  config.x.core_api_token_ttl = ENV['CORE_API_TOKEN_TTL'] ? ENV['CORE_API_TOKEN_TTL'].to_i.seconds : 30.minutes

  config.x.core_api_token_iss = ENV['CORE_API_TOKEN_ISS'] || 'SciNote'

  config.x.core_api_rate_limit = ENV['CORE_API_RATE_LIMIT'] ? ENV['CORE_API_RATE_LIMIT'].to_i : 1000

  config.x.core_api_v1_enabled = ENV['CORE_API_V1_ENABLED'] || false
end
