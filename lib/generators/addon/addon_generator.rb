class AddonGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  argument :name, type: :string

  def initialize_vars
    @modules = name.split('::')
    @folders = @modules.map(&:underscore)
    @full_underscore_name = @folders.join('_')
    @folders_path = @folders.join('/')
    @addon_name = @folders[-1]
  end

  def create_app
    # app/assets
    create_file(
      "addons/#{@addon_name}/app/assets/images/#{@folders_path}/.keep"
    )
    create_file(
      "addons/#{@addon_name}/app/assets/" \
      "javascripts/#{@folders_path}/application.js"
    )
    copy_file(
      'application.scss',
      "addons/#{@addon_name}/app/assets/" \
      "stylesheets/#{@folders_path}/application.scss"
    )

    # app/controllers
    create_file(
      "addons/#{@addon_name}/app/controllers/" \
      "#{@folders_path}/application_controller.rb"
    ) do
      embed_into_modules do
        "class ApplicationController < ::ApplicationController\nend\n"
      end
    end

    # app/decorators
    create_file("addons/#{@addon_name}/app/decorators/controllers/.keep")
    create_file("addons/#{@addon_name}/app/decorators/models/.keep")

    # app/helpers
    create_file(
      "addons/#{@addon_name}/app/helpers/" \
      "#{@folders_path}/application_helper.rb"
    ) do
      embed_into_modules do
        "module ApplicationHelper\nend\n"
      end
    end

    # app/models
    create_file("addons/#{@addon_name}/app/models/#{@folders_path}/.keep")

    # app/overrides
    create_file("addons/#{@addon_name}/app/overrides/.keep")

    # app/views
    create_file(
      "addons/#{@addon_name}/app/views/layouts/#{@folders_path}/.keep"
    )
    create_file(
      "addons/#{@addon_name}/app/views/#{@folders_path}/overrides/.keep"
    )
  end

  def create_bin
    file_path = "addons/#{@addon_name}/bin/rails"
    copy_file('rails', file_path)
    gsub_file(file_path, '${FOLDERS_PATH}', @folders_path)
  end

  def create_config
    # config/initializers
    create_file(
      "addons/#{@addon_name}/config/initializers/" \
      "#{@folders_path}/constants.rb"
    ) do
      embed_into_modules do
        "class Constants\nend\n"
      end
    end

    # config/locales
    create_file(
      "addons/#{@addon_name}/config/locales/en.yml"
    ) do
      "en:\n"
    end

    # config/routes.rb
    create_file(
      "addons/#{@addon_name}/config/routes.rb"
    ) do
      "#{name}::Engine.routes.draw do\nend\n"
    end
  end

  def create_db
    create_file("addons/#{@addon_name}/db/migrate/.keep")
  end

  def create_lib
    # lib/.../engine.rb
    file_path = "addons/#{@addon_name}/lib/#{@folders_path}/engine.rb"
    create_file(
      file_path
    ) do
      embed_into_modules { File.read("#{@source_paths[0]}/engine.rb") }
    end
    gsub_file(file_path, '${FULL_UNDERSCORE_NAME}', @full_underscore_name)
    gsub_file(file_path, '${NAME}', name)
    gsub_file(file_path, '${FOLDERS_PATH}', @folders_path)
    gsub_file(file_path, '${ADDON_NAME}', @addon_name)

    # lib/.../version.rb
    dots = @modules.map { '/..' }.join
    create_file(
      "addons/#{@addon_name}/lib/" \
      "#{@folders_path}/version.rb"
    ) do
      embed_into_modules do
        "VERSION =\n" \
        "  File.read(\n" \
        "    \"\#{File.dirname(__FILE__)}#{dots}/../VERSION\"\n" \
        "  ).strip.freeze\n"
      end
    end

    # lib/.../<engine>.rb
    folders_path_n = @folders[0..-2].join('/')
    file_name = @folders[-1]
    create_file(
      "addons/#{@addon_name}/lib/" \
      "#{folders_path_n}/#{file_name}.rb"
    ) do
      embed_into_modules { '' }
    end

    # lib/tasks
    create_file("addons/#{@addon_name}/lib/tasks/#{@folders_path}/.keep")

    # lib/engine.rb
    create_file(
      "addons/#{@addon_name}/lib/#{@full_underscore_name}.rb"
    ) do
      "require '#{@folders_path}'\n" \
      "require '#{@folders_path}/engine'\n"
    end
  end

  def create_root
    copy_file('.gitignore', "addons/#{@addon_name}/.gitignore")
    copy_file('Gemfile', "addons/#{@addon_name}/Gemfile")
    copy_file('LICENSE.txt', "addons/#{@addon_name}/LICENSE.txt")
    file_path = "addons/#{@addon_name}/README.md"
    copy_file('README.md', file_path)
    gsub_file(file_path, '${ADDON_NAME}', @addon_name)
    gsub_file(file_path, '${FULL_UNDERSCORE_NAME}', @full_underscore_name)
    gsub_file(file_path, '${NAME}', name)
    gsub_file(file_path, '${FOLDERS_PATH}', @folders_path)
    create_file("addons/#{@addon_name}/VERSION") { '0.0.1' }

    # Rakefile
    file_path = "addons/#{@addon_name}/Rakefile"
    copy_file('Rakefile', file_path)
    gsub_file(file_path, '${NAME}', name)

    # <engine>.gemspec
    file_path = "addons/#{@addon_name}/#{@full_underscore_name}.gemspec"
    copy_file('.gemspec', file_path)
    gsub_file(file_path, '${FOLDERS_PATH}', @folders_path)
    gsub_file(file_path, '${FULL_UNDERSCORE_NAME}', @full_underscore_name)
    gsub_file(file_path, '${NAME}', name)
  end

  private

  def embed_into_modules
    res = ''
    @modules.each_with_index do |mod, i|
      res << '  ' * i
      res << "module #{mod}\n"
    end
    block_res = yield
    block_res.each_line do |line|
      if line == "\n"
        res << "\n"
      else
        res << '  ' * @modules.count
        res << line
      end
    end
    @modules.each_with_index do |_, i|
      res << '  ' * (@modules.count - 1 - i)
      res << "end\n"
    end
    res
  end
end
