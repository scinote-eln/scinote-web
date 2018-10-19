Api.configure do |config|
  if ENV['CORE_API_SIGN_ALG']
    config.core_api_sign_alg = ENV['CORE_API_SIGN_ALG']
  end
  if ENV['CORE_API_TOKEN_TTL']
    config.core_api_token_ttl = ENV['CORE_API_TOKEN_TTL'].to_i.seconds
  end
  if ENV['CORE_API_TOKEN_ISS']
    config.core_api_token_iss = ENV['CORE_API_TOKEN_ISS']
  end

  config.core_api_rate_limit = ENV['CORE_API_RATE_LIMIT'].to_i || 1000

  config.core_api_v1_preview = true if ENV['CORE_API_V1_PREVIEW']

  Paperclip::DataUriAdapter.register if ENV['CORE_API_V1_PREVIEW']

  vars = ENV.select { |name, _| name =~ /^[[:alnum:]]*_AZURE_AD_APP_ID/ }
  vars.each do |name, value|
    app_name = name.sub('_AZURE_AD_APP_ID', '')
    config.azure_ad_apps[value] = {}

    iss = ENV["#{app_name}_AZURE_AD_ISS"]
    raise StandardError, "No ISS for #{app_name} Azure app" unless iss
    config.azure_ad_apps[value][:iss] = iss

    conf_url = ENV["#{app_name}_AZURE_AD_CONF_URL"]
    raise StandardError, "No CONF_URL for #{app_name} Azure app" unless conf_url
    config.azure_ad_apps[value][:conf_url] = conf_url

    provider = ENV["#{app_name}_AZURE_AD_PROVIDER_NAME"]
    unless provider
      raise StandardError, "No PROVIDER_NAME for #{app_name} Azure app"
    end
    config.azure_ad_apps[value][:provider] = provider
  end
end
