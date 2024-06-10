require 'silencer/rails/logger'

Rails.application.configure do
  config.middleware.swap(
    Rails::Rack::Logger,
    Silencer::Logger,
    config.log_tags,
    silence: [
      '/api/health',
      '/health'
    ]
  )
end
