Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = false

  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  Rails.application.routes.default_url_options = {
    host: Rails.application.secrets.mail_server_url
  }

  # Don't care if the mailer can't send.
  config.action_mailer.default_url_options = {
    host: Rails.application.secrets.mail_server_url
  }
  config.action_mailer.default_options = {
    from: Rails.application.secrets.mailer_from,
    reply_to: Rails.application.secrets.mailer_reply_to
  }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp

  config.action_mailer.smtp_settings = {
    address: Rails.application.secrets.mailer_address,
    port: Rails.application.secrets.mailer_port,
    domain: Rails.application.secrets.mailer_domain,
    authentication: Rails.application.secrets.mailer_authentication,
    enable_starttls_auto: true,
    user_name: Rails.application.secrets.mailer_user_name,
    password: Rails.application.secrets.mailer_password,
    openssl_verify_mode: Rails.application.secrets.mailer_openssl_verify_mode,
    ca_path: Rails.application.secrets.mailer_openssl_ca_path,
    ca_file: Rails.application.secrets.mailer_openssl_ca_file
  }

  #config.action_mailer.perform_deliveries = false
  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true


  # Compress JavaScripts and CSS.
  config.assets.js_compressor = Uglifier.new(harmony: true)
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = ENV['ACTIVESTORAGE_SERVICE'] || :local

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV['RAILS_FORCE_SSL'].present?

  config.ssl_options = { redirect: { exclude: ->(request) { request.path =~ %r{api\/health} } } }

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]




  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

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

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Use a different cache store in production.
  config.cache_store = :memory_store, { size: (ENV['RAILS_MEM_CACHE_SIZE_MB'] || 32).to_i.megabytes }

  # Use a real queuing backend for Active Job (and separate queues per environment)
  config.active_job.queue_adapter     = :delayed_job
  config.active_job.queue_name_prefix = "scinote_#{Rails.env}"
  config.action_mailer.perform_caching = false
  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  # Enable new team on sign up
  new_team_on_signup = ENV['NEW_TEAM_ON_SIGNUP'] || 'true'
  if new_team_on_signup == 'true'
    config.x.new_team_on_signup = true
  else
    config.x.new_team_on_signup = false
  end
end
