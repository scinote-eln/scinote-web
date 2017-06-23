require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scinote
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.encoding = 'utf-8'

    config.active_job.queue_adapter = :delayed_job

    # Do not swallow errors in after_commit/after_rollback callbacks.
    #  config.active_record.raise_in_transactional_callbacks = true

    # Logging
    config.log_formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime}] #{severity}: #{msg}\n"
    end

    # Paperclip spoof checking
    Paperclip.options[:content_type_mappings] = {
      csv: 'text/plain',
      wopitest: ['text/plain', 'inode/x-empty']
    }
  end
end
