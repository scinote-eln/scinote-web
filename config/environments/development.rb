Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.default_url_options = {
    host: Rails.application.secrets.mail_server_url
  }
  config.action_mailer.default_options = {
    from: Rails.application.secrets.mailer_from,
    reply_to: Rails.application.secrets.mailer_reply_to
  }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp

  config.action_mailer.smtp_settings = {
    address: Rails.application.secrets.mailer_address,
    port: Rails.application.secrets.mailer_port,
    domain: Rails.application.secrets.mailer_domain,
    authentication: "plain",
    enable_starttls_auto: true,
    user_name: Rails.application.secrets.mailer_user_name,
    password: Rails.application.secrets.mailer_password
  }
  #config.action_mailer.perform_deliveries = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Only log info and higher on development
  config.log_level = :info

  # Only allow Better Errors to work on trusted ip, use ifconfig to see which
  # one you use and put it into application.yml!
  BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] if ENV['TRUSTED_IP']

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  # Enable first-time tutorial for users signing in the sciNote for
  # the first time.
  config.x.enable_tutorial = ENV['ENABLE_TUTORIAL'] == 'true'

  # Enable reCAPTCHA
  config.x.enable_recaptcha = ENV['ENABLE_RECAPTCHA'] == 'true'
end
