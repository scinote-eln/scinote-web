Api.configure do |config|
  if ENV['CORE_API_SIGN_ALG']
    config.core_api_sign_alg = ENV['CORE_API_SIGN_ALG']
  end
  if ENV['CORE_API_TOKEN_TTL']
    config.core_api_token_ttl = ENV['CORE_API_TOKEN_TTL']
  end
  if ENV['CORE_API_TOKEN_ISS']
    config.core_api_token_iss = ENV['CORE_API_TOKEN_ISS']
  end
end
