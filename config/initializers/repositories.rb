Rails.application.configure do
  # Maximum number of repositories per team allowed
  config.x.team_repositories_limit =
    if ENV['TEAM_REPOSITORIES_LIMIT']
      ENV['TEAM_REPOSITORIES_LIMIT'].to_i
    else
      Constants::DEFAULT_TEAM_REPOSITORIES_LIMIT
    end

  config.x.global_repositories_limit =
    if ENV['GLOBAL_REPOSITORIES_LIMIT']
      ENV['GLOBAL_REPOSITORIES_LIMIT'].to_i
    else
      0
    end
end
