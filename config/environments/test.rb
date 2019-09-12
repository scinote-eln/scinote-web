Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = false

  # Settings specified here will take precedence over those in config/application.rb.

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.seconds.to_i}"
  }

  # Enable this to be able to output stuff to STDOUT during tests
  # via Rails::logger.info "..."
  config.logger = Logger.new(STDOUT)
  config.log_level = :info

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static file server for tests with Cache-Control for performance.
  config.serve_static_files   = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  config.action_mailer.perform_deliveries = true

  Rails.application.routes.default_url_options = {
    host: Rails.application.secrets.mail_server_url
  }

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  config.logger = Logger.new(STDOUT)
  config.log_level = :error

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Enable/disable Deface
  config.deface.enabled = ENV['DEFACE_ENABLED'] != 'false'

  # Enable reCAPTCHA
  config.x.enable_recaptcha = false

  # Enable email confirmations
  config.x.enable_email_confirmations = false

  # Enable user registrations
  config.x.enable_user_registration = true

  # disable sign in with LinkedIn account
  config.x.linkedin_signin_enabled = false

  # enable assets compiling
  config.assets.compile = true
end
