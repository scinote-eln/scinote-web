class Engine < ::Rails::Engine
  engine_name '${FULL_UNDERSCORE_NAME}'
  isolate_namespace ${NAME}
  paths['app/views'] << 'app/views/${FOLDERS_PATH}'

  # Precompile engine-specific assets
  initializer '${ADDON_NAME}.assets.precompile' do |app|
    app.config.assets.precompile += %w(
    )
  end

  # Include static assets
  initializer :static_assets do |app|
    app.middleware.insert_before(
      ::ActionDispatch::Static,
      ::ActionDispatch::Static,
      "#{root}/public"
    )
  end

  # Merge localization files from engine
  initializer :load_localization do |app|
    app.config.i18n.load_path += Dir[
      Rails.root.join(
        'addons',
        '${ADDON_NAME}',
        'config',
        'locales',
        '*.{rb,yml}'
      )
    ]
  end

  # Initialize migrations
  initializer :append_migrations do |app|
    unless app.root.to_s.match(root.to_s)
      config.paths['db/migrate'].expanded.each do |p|
        app.config.paths['db/migrate'] << p
      end
    end
  end

  # Initialize decorators
  config.to_prepare do
    Dir.glob(Engine.root.join('app',
                              'decorators',
                              '**',
                              '*_decorator*.rb')) do |c|
      Rails.configuration.cache_classes ? require(c) : load(c)
    end
  end
end
