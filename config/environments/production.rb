require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = ENV['RAILS_DISABLE_EAGER_LOAD'] != 'true'

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  Rails.application.routes.default_url_options = {
    host: ENV['WEB_SERVER_URL'] || ENV['MAIL_SERVER_URL']
  }

  config.action_mailer.default_url_options = { host: Rails.application.routes.default_url_options[:host] }

  if ENV['MAIL_FROM'] # don't try and configure if mailing config is not present
    config.action_mailer.default_options = {
      from: ENV.fetch('MAIL_FROM'),
      reply_to: ENV.fetch('MAIL_REPLYTO')
    }
  end

  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = ENV['SMTP_USE_AWS_SES'] == 'true' ? :ses : :smtp

  if ENV['SMTP_ADDRESS'] # don't try and configure if SMTP config is not present
    config.action_mailer.smtp_settings = {
      address: ENV.fetch('SMTP_ADDRESS'),
      port: ENV.fetch('SMTP_PORT', '587'),
      domain: ENV.fetch('SMTP_DOMAIN'),
      authentication: ENV.fetch('SMTP_AUTH_METHOD', 'plain'),
      enable_starttls_auto: true,
      user_name: ENV.fetch('SMTP_USERNAME', nil),
      password: ENV.fetch('SMTP_PASSWORD', nil),
      openssl_verify_mode: ENV.fetch('SMTP_OPENSSL_VERIFY_MODE', 'peer'),
      ca_path: ENV.fetch('SMTP_OPENSSL_CA_PATH', '/etc/ssl/certs'),
      ca_file: ENV.fetch('SMTP_OPENSSL_CA_FILE', '/etc/ssl/certs/ca-certificates.crt')
    }
  end

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  # Set to nil to fix builds in production (https://github.com/sass/sassc-rails/issues/93)
  config.assets.css_compressor = nil

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = ENV['ACTIVESTORAGE_SERVICE'] || :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV['RAILS_FORCE_SSL'].present?

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }
  config.ssl_options = { redirect: { exclude: ->(request) { request.path =~ %r{api/health|status} } } }

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # "info" includes generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "scinote_production"

  # Disable caching for Action Mailer templates even if Action Controller
  # caching is enabled.
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

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

  # Set up domain for pwa SciNote mobile app
  config.x.pwa_domain = ENV['PWA_DOMAIN'] || 'm.scinote.net'

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new "app-name")

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }


  # Use a different cache store in production.
  config.cache_store = :memory_store, { size: (ENV['RAILS_MEM_CACHE_SIZE_MB'] || 32).to_i.megabytes }

  # Use a real queuing backend for Active Job (and separate queues per environment)
  config.active_job.queue_adapter     = :delayed_job
  config.active_job.queue_name_prefix = "scinote_#{Rails.env}"
  config.action_mailer.perform_caching = false
  # Enable new team on sign up
  new_team_on_signup = ENV['NEW_TEAM_ON_SIGNUP'] || 'true'
  if new_team_on_signup == 'true'
    config.x.new_team_on_signup = true
  else
    config.x.new_team_on_signup = false
  end
end
