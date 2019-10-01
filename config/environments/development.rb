Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = true

  # Settings specified here will take precedence over those in config/application.rb.

  config.after_initialize do
    Bullet.enable        = true
    Bullet.bullet_logger = true
    Bullet.raise         = false # raise an error if n+1 query occurs
  end

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = ENV['WORKER'] ? true : false
  # Do not eager load code on boot.
  config.eager_load = ENV['WORKER'] ? true : false

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  Rails.application.routes.default_url_options = {
    host: Rails.application.secrets.mail_server_url
  }

  config.action_mailer.default_options = {
    from: Rails.application.secrets.mailer_from,
    reply_to: Rails.application.secrets.mailer_reply_to
  }


  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = {
    host: Rails.application.secrets.mail_server_url
  }
  config.action_mailer.perform_deliveries = false


  config.action_mailer.smtp_settings = {
    address: Rails.application.secrets.mailer_address,
    port: Rails.application.secrets.mailer_port,
    domain: Rails.application.secrets.mailer_domain,
    authentication: Rails.application.secrets.mailer_authentication,
    enable_starttls_auto: true,
    user_name: Rails.application.secrets.mailer_user_name,
    password: Rails.application.secrets.mailer_password
  }


  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = ENV['ACTIVESTORAGE_SERVICE'] || :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  config.action_mailer.preview_path = "#{Rails.root}/test/mailers/previews"

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

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
  config.log_level = :debug

  # Only allow Better Errors to work on trusted ip, use ifconfig to see which
  # one you use and put it into application.yml!
  BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] if ENV['TRUSTED_IP']

  # Suppress logger output for asset requests.
  config.assets.quiet = false

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  # Enable/disable Deface
  config.deface.enabled = ENV['DEFACE_ENABLED'] != 'false'

  # Enable reCAPTCHA
  config.x.enable_recaptcha = ENV['ENABLE_RECAPTCHA'] == 'true'

  # Enable email confirmations
  config.x.enable_email_confirmations =
    ENV['ENABLE_EMAIL_CONFIRMATIONS'] == 'true'

  # Enable user registrations
  config.x.enable_user_registration =
    ENV['ENABLE_USER_REGISTRATION'] == 'false' ? false : true

  # Enable sign in with LinkedIn account
  config.x.linkedin_signin_enabled = ENV['LINKEDIN_SIGNIN_ENABLED'] == 'true'

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store, { size: (ENV['RAILS_MEM_CACHE_SIZE_MB'] || 32).to_i.megabytes }
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end
  # Enable new team on sign up
  new_team_on_signup = ENV['NEW_TEAM_ON_SIGNUP'] || 'true'
  if new_team_on_signup == 'true'
    config.x.new_team_on_signup = true
  else
    config.x.new_team_on_signup = false
  end
end
