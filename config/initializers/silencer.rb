require 'silencer/logger'

Rails.application.configure do
  config.middleware.swap(
    Rails::Rack::Logger,
    Silencer::Logger,
    config.log_tags,
    silence: [
      # Silence WickedPDF rendering in logs
      %r{/projects/[0-9]*/reports/generate.pdf},
      '/api/health'
    ]
  )
end
