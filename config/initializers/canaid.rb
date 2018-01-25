Canaid.configure do |config|
  config.permissions_paths << 'app/permissions/**/*.rb'
  config.permissions_paths << 'addons/**/app/permissions/**/*.rb'
end