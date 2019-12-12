# frozen_string_literal: true

Rails.application.configure do
  vars = ENV.select { |name, _| name =~ /^[[:alnum:]]*_AZURE_AD_APP_ID/ }
  config.x.azure_ad_apps = HashWithIndifferentAccess.new if vars.present?

  vars.each do |name, value|
    app_name = name.sub('_AZURE_AD_APP_ID', '')
    config.x.azure_ad_apps[value] = {}

    iss = ENV["#{app_name}_AZURE_AD_ISS"]
    raise StandardError, "No ISS for #{app_name} Azure app" unless iss

    config.x.azure_ad_apps[value][:iss] = iss

    conf_url = ENV["#{app_name}_AZURE_AD_CONF_URL"]
    raise StandardError, "No CONF_URL for #{app_name} Azure app" unless conf_url

    config.x.azure_ad_apps[value][:conf_url] = conf_url

    provider = ENV["#{app_name}_AZURE_AD_PROVIDER_NAME"]
    raise StandardError, "No PROVIDER_NAME for #{app_name} Azure app" unless provider

    config.x.azure_ad_apps[value][:provider] = provider

    config.x.azure_ad_apps[value][:enable_sign_in] = ENV["#{app_name}_AZURE_AD_ENABLE_SIGN_IN"] == 'true'

    next unless config.x.azure_ad_apps[value][:enable_sign_in]

    config.x.azure_ad_apps[value][:sign_in_label] = ENV["#{app_name}_AZURE_AD_SIGN_IN_LABEL"] || 'Sign in with Azure AD'
    config.x.azure_ad_apps[value][:auto_link_on_sign_in] = ENV["#{app_name}_AZURE_AD_AUTO_LINK_ON_SIGN_IN"] == 'true'

    if ENV["#{app_name}_AZURE_AD_SIGN_IN_POLICY"]
      config.x.azure_ad_apps[value][:sign_in_policy] = ENV["#{app_name}_AZURE_AD_SIGN_IN_POLICY"]
    end
  end
end
