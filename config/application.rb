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
require 'datadog/auto_instrument' if ENV['DD_TRACE_ENABLED'] == 'true'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scinote
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets generators tasks])

    # Autoload nested omniauth lib paths
    config.autoload_paths << Rails.root.join('lib/omniauth/strategies')

    config.add_autoload_paths_to_load_path = true

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Addon autoloading configuration

    # Load custom database adapters from addons
    Dir.glob(Rails.root.glob('addons/*/lib/active_record/connection_adapters/*.rb')) do |c|
      Rails.configuration.cache_classes ? require(c) : load(c)
    end

    Rails.autoloaders.main.ignore(Rails.root.join('addons/*/app/decorators'))
    Rails.autoloaders.main.ignore(Rails.root.join('addons/*/app/overrides'))

    # Add rack-attack middleware for request rate limiting
    config.middleware.use Rack::Attack

    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    config.encoding = 'utf-8'

    config.active_job.queue_adapter = :delayed_job

    config.action_dispatch.cookies_serializer = :hybrid

    config.action_view.preload_links_header = false if ENV['RAILS_NO_PRELOAD_LINKS_HEADER'] == 'true'

    # Max uploaded file size in MB
    config.x.file_max_size_mb = (ENV['FILE_MAX_SIZE_MB'] || 50).to_i

    config.x.webhooks_enabled = ENV['ENABLE_WEBHOOKS'] == 'true'

    config.x.connected_devices_enabled = ENV['CONNECTED_DEVICES_ENABLED'] == 'true'

    config.x.custom_sanitizer_config = nil

    config.x.no_external_csp_exceptions = ENV['SCINOTE_NO_EXT_CSP_EXCEPTIONS'] == 'true'

    config.x.export_all_limit_24h = (ENV['EXPORT_ALL_LIMIT_24_HOURS'] || 3).to_i

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

    ActiveRecord::SessionStore::Session.serializer = :json
  end
end
