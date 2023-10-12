require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scinote
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    Rails.autoloaders.main.ignore(Rails.root.join('addons/*/app/decorators'))
    # Add rack-attack middleware for request rate limiting
    config.middleware.use Rack::Attack

    # Swap the Rack::MethodOverride with a wrapped middleware for WOPI handling
    require_relative '../app/middlewares/wopi_method_override'
    config.middleware.swap Rack::MethodOverride, WopiMethodOverride

    # Load all model concerns, including subfolders
    config.autoload_paths += Dir["#{Rails.root}/app/models/concerns/**/*.rb"]

    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    config.encoding = 'utf-8'

    config.active_job.queue_adapter = :delayed_job

    config.action_dispatch.cookies_serializer = :hybrid

    # Max uploaded file size in MB
    config.x.file_max_size_mb = (ENV['FILE_MAX_SIZE_MB'] || 50).to_i

    config.x.webhooks_enabled = ENV['ENABLE_WEBHOOKS'] == 'true'

    config.x.connected_devices_enabled = ENV['CONNECTED_DEVICES_ENABLED'] == 'true'

    config.x.custom_sanitizer_config = nil

    # Logging
    config.log_formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime}] #{severity}: #{msg}\n"
    end

    # SciNote Core Application version
    VERSION = File.read(Rails.root.join('VERSION')).strip.freeze

    # Doorkeeper overrides
    config.to_prepare do
      # Only Authorization endpoint
      Doorkeeper::AuthorizationsController.layout 'sign_in_halt'

      # Add connected device logging when creating tokens
      Doorkeeper::TokensController.include(Doorkeeper::ConnectedDeviceLogging)
    end

    config.action_view.field_error_proc = Proc.new { |html_tag, instance|
      "<div class=\"field_with_errors sci-input-container\">#{html_tag}</div>".html_safe
    }
  end
end
