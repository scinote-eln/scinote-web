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

  # Checking additional configurations in ApplicationSettings JSON. Key and values should be strings there.
  begin
    if ApplicationSettings.instance.values['azure_ad_apps']&.is_a?(Array)
      config.x.azure_ad_apps ||= HashWithIndifferentAccess.new
      settings = ApplicationSettings.instance

      settings.values['azure_ad_apps'].each do |azure_ad_app|
        app_config = {}
        app_id = azure_ad_app['app_id']
        Rails.logger.error('No app_id present for the entry in Azure app settings') && next unless app_id

        app_config[:iss] = azure_ad_app['iss']
        Rails.logger.error("No iss for #{app_id} Azure app") && next unless app_config[:iss]

        app_config[:conf_url] = azure_ad_app['conf_url']
        Rails.logger.error("No conf_url for #{app_id} Azure app") && next unless app_config[:conf_url]

        app_config[:provider] = azure_ad_app['provider_name']
        Rails.logger.error("No provider_name for #{app_id} Azure app") && next unless app_config[:provider]

        app_config[:enable_sign_in] = azure_ad_app['enable_sign_in'] == 'true'

        if app_config[:enable_sign_in]
          app_config[:sign_in_label] = azure_ad_app['sign_in_label'] || 'Sign in with Azure AD'
          app_config[:auto_link_on_sign_in] = azure_ad_app['auto_link_on_sign_in'] == 'true'
          app_config[:sign_in_policy] = azure_ad_app['sign_in_policy'] if azure_ad_app['sign_in_policy']
        end

        config.x.azure_ad_apps[app_id] = app_config
      end
    end
  rescue ActiveRecord::ActiveRecordError, PG::ConnectionBad
    Rails.logger.info('Not connected to database, skipping additional Azure AD configuration')
  end
end
