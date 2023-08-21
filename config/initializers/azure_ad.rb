# frozen_string_literal: true

ActiveSupport::Reloader.to_prepare do
  azure_app_ids = ENV.select { |name, _| name =~ /^[[:alnum:]]*_AZURE_AD_APP_ID/ }
  settings = ApplicationSettings.instance
  settings.values['azure_ad_apps'] ||= []

  azure_app_ids.each do |name, value|
    app_name = name.sub('_AZURE_AD_APP_ID', '')
    app_config = {}
    app_config['app_id'] = value

    tenant_id = ENV.fetch("#{app_name}_AZURE_AD_TENANT_ID")
    raise StandardError, "No Tenant ID for #{app_name} Azure app" unless tenant_id

    app_config['tenant_id'] = tenant_id

    client_secret = ENV.fetch("#{app_name}_AZURE_AD_CLIENT_SECRET")
    raise StandardError, "No Client Secret for #{app_name} Azure app" unless client_secret

    app_config['client_secret'] = client_secret

    iss = ENV.fetch("#{app_name}_AZURE_AD_ISS")
    raise StandardError, "No ISS for #{app_name} Azure app" unless iss

    app_config['iss'] = iss

    conf_url = ENV.fetch("#{app_name}_AZURE_AD_CONF_URL")
    raise StandardError, "No CONF_URL for #{app_name} Azure app" unless conf_url

    app_config['conf_url'] = conf_url

    provider = ENV.fetch("#{app_name}_AZURE_AD_PROVIDER_NAME")
    raise StandardError, "No PROVIDER_NAME for #{app_name} Azure app" unless provider

    app_config['provider_name'] = provider

    app_config['enable_sign_in'] = ENV["#{app_name}_AZURE_AD_ENABLE_SIGN_IN"] == 'true'

    next unless app_config['enable_sign_in']

    app_config['sign_in_label'] = ENV.fetch("#{app_name}_AZURE_AD_SIGN_IN_LABEL")
    app_config['auto_link_on_sign_in'] = ENV["#{app_name}_AZURE_AD_AUTO_LINK_ON_SIGN_IN"] == 'true'

    if ENV["#{app_name}_AZURE_AD_SIGN_IN_POLICY"]
      app_config['sign_in_policy'] = ENV["#{app_name}_AZURE_AD_SIGN_IN_POLICY"]
    end

    existing_index = settings.values['azure_ad_apps'].find_index { |v| v['app_id'] == value }
    if existing_index
      settings.values['azure_ad_apps'][existing_index] = app_config
    else
      settings.values['azure_ad_apps'] << app_config
    end
  end
  settings.save! if azure_app_ids.present?
rescue ActiveRecord::ActiveRecordError, PG::ConnectionBad
  Rails.logger.info('Not connected to database, skipping additional Azure AD configuration')
end
