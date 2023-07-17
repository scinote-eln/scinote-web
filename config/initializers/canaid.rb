ActiveSupport::Reloader.to_prepare do
  Canaid.configure do |config|
    extend AddonsHelper

    config.permissions_paths << 'app/permissions/**/*.rb'

    # Include the included addons' permissions folders
    rx = %r{^.*(addons/.*/app/permissions)$}
    list_all_addons.each do |addon|
      full_path = addon::Engine
                  .instance
                  .config
                  .eager_load_paths
                  .find { |p| p.ends_with?('permissions') }
      next unless full_path

      res = rx.match(full_path)
      config.permissions_paths << "#{res[1]}/**/*.rb" if res && res.length > 1
    end
  end
end
