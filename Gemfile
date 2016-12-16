source 'http://rubygems.org'

ruby '2.2.4'

gem 'rails', '4.2.5'
gem 'figaro'
gem 'pg'
gem 'devise', '3.5.6'
gem 'devise_invitable'
gem 'bootstrap-sass', '~> 3.3.5'
gem 'sass-rails', '~> 5.0'
gem 'bootstrap_form'
gem 'yomu'
gem 'font-awesome-rails', '~> 4.6'

# JS datetime library, requirement of datetime picker
gem 'momentjs-rails', '>= 2.9.0'
# JS datetime picker
gem 'bootstrap3-datetimepicker-rails', '~> 4.15.35'
# Select elements for Bootstrap
gem 'bootstrap-select-rails'
gem 'uglifier', '>= 1.3.0'
# jQuery & plugins
gem 'jquery-turbolinks'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-scrollto-rails'
gem 'hammerjs-rails'
gem 'introjs-rails' # Create quick tutorials
gem 'js_cookie_rails' # Simple JS API for cookies
gem 'spinjs-rails'
gem 'autosize-rails' # jQuery autosize plugin

gem 'underscore-rails'
gem 'turbolinks'
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'bcrypt', '~> 3.1.10'
gem 'logging', '~> 2.0.0'
gem 'aspector' # Aspect-oriented programming for Rails
gem 'rgl' # Graph framework for project diagram calculations
gem 'nested_form_fields'
gem 'ajax-datatables-rails', '~> 0.3.1'
gem 'commit_param_routing' # Enables different submit actions in the same form to route to different actions in controller
gem 'kaminari'
gem "i18n-js", ">= 3.0.0.rc11" # Localization in javascript files
gem 'roo', '~> 2.1.0' # Spreadsheet parser
gem 'wicked_pdf'
gem 'wkhtmltopdf-heroku'
gem 'remotipart', '~> 1.2' # Async file uploads
gem 'faker' # Generate fake data
gem 'auto_strip_attributes', '~> 2.1' # Removes unnecessary whitespaces from ActiveRecord or ActiveModel attributes
gem 'deface', '~> 1.0'
gem 'nokogiri' # HTML/XML parser
gem 'sneaky-save', git: 'git://github.com/einzige/sneaky-save.git'

gem 'paperclip', '~> 4.3' # File attachment, image attachment library
gem 'aws-sdk', '~> 2.2.8'
gem 'aws-sdk-v1'
gem 'delayed_job_active_record'
gem 'devise-async'
gem 'ruby-graphviz', '~> 1.2' # Graphviz for rails
gem 'quill-rails', # Rich text editor
    git: 'https://github.com/biosistemika/quill-rails.git',
    ref: 'e765c04'

group :development, :test do
  gem 'byebug'
  gem 'web-console', '~> 2.0'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'awesome_print'
  gem 'rubocop', require: false
  gem 'scss_lint', require: false
  gem 'starscope', require: false
end

group :production do
  gem 'puma'
  gem 'rails_12factor'
  gem 'skylight'
end

group :test do
  gem 'minitest-reporters', '~> 1.1'
  gem "shoulda-context"
  gem "shoulda-matchers", ">= 3.0.1"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
