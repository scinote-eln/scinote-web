# frozen_string_literal: true

# Only check if connection works when server starts, and if WOPI is
# enabled
if defined?(Rails::Server).present? && ENV['WOPI_ENABLED'] == 'true'
  missing_vars = []
  %w(
    WOPI_TEST_ENABLED WOPI_DISCOVERY_URL WOPI_ENDPOINT_URL USER_SUBDOMAIN
    WOPI_SUBDOMAIN WOPI_USER_HOST
  ).each do |var_name|
    missing_vars << var_name if ENV[var_name].blank?
  end

  unless missing_vars.empty?
    puts "WARNING: Due to WOPI_ENABLED == 'true', " \
         "following env. variables MUST also be specified: " \
         "#{missing_vars.join(', ')}; " \
         "aborting."
    abort
  end
end
