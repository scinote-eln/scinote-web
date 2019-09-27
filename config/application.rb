require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scinote
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    Rails.autoloaders.main.ignore(Rails.root.join('addons', '*', 'app', 'decorators'))

    # config.add_autoload_paths_to_load_path = false

    config.active_record.schema_format = :sql

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

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

    # Max uploaded file size in MB
    config.x.file_max_size_mb = (ENV['FILE_MAX_SIZE_MB'] || 50).to_i

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
    end
  end
end
