Rails.application.configure do
  # Maximum number of repositories per team allowed
  config.x.repositories_limit =
    if ENV['REPOSITORIES_LIMIT']
      ENV['REPOSITORIES_LIMIT'].to_i
    else
      5
    end
end
