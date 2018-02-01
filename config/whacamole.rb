# https://github.com/arches/whacamole
#
# Steps to setup this on your heroku instance, this will affect only the worker
#
# 1) set the env variables (api token: > heroku auth:token)
# 2) > heroku labs:enable log-runtime-metrics --app YOUR_APP_NAME
# 3) > heroku ps:scale whacamole=1 --app YOUR_APP_NAME

Whacamole.configure(ENV['HEROKU_APP_NAME']) do |config|
  config.api_token = ENV['HEROKU_API_TOKEN']
  config.dynos = %w{worker}
  config.restart_threshold = ENV['WHACAMOLE_DYNO_RESTART_THRESHOLD'].to_i
  config.restart_window = ENV['WHACAMOLE_DYNO_RESTART_TIME_IN_SEC'].to_i
end
