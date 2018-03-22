Rails.application.configure do
  config.force_ssl = (ENV['FORCE_SSL'] == '1')
end

