Api.configure do |config|
  config.core_api_sign_alg = ENV['API_SIGN_ALG'] if ENV['CORE_API_SIGN_ALG']
  config.core_api_token_ttl = ENV['API_TOKEN_TTL'] if ENV['CORE_API_TOKEN_TTL']
  config.core_api_token_iss = ENV['API_TOKEN_ISS'] if ENV['CORE_API_TOKEN_ISS']
end
