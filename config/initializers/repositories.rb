Rails.application.configure do
  # Maximum number of repositories per team allowed
  config.x.repositories_limit = ENV['REPOSITORIES_LIMIT'].to_i || 5
end
