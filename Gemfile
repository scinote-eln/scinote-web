source 'http://rubygems.org'

ruby '2.4.4'

gem 'rails', '5.1.6'
gem 'webpacker', '~> 2.0'
gem 'figaro'
gem 'pg', '~> 0.18'
gem 'devise', '~> 4.3.0'
gem 'devise_invitable'
gem 'simple_token_authentication', '~> 1.15.1' # Token authentication for Devise
gem 'bootstrap-sass', '~> 3.3.7'
gem 'sass-rails', '~> 5.0.6'
gem 'bootstrap_form'
gem 'yomu'
gem 'recaptcha', require: 'recaptcha/rails'
gem 'sanitize', '~> 4.4'

# Gems for OAuth2 subsystem
gem 'doorkeeper', '>= 4.6'
gem 'omniauth'
gem 'omniauth-linkedin-oauth2'

# Gems for API implementation
gem 'active_model_serializers', '~> 0.10.7'
gem 'json-jwt'
gem 'jwt', '~> 1.5'
gem 'kaminari'
gem 'rack-attack'

# JS datetime library, requirement of datetime picker
gem 'momentjs-rails', '~> 2.17.1'
# JS datetime picker
gem 'bootstrap3-datetimepicker-rails', '~> 4.15.35'
# Select elements for Bootstrap
gem 'bootstrap-select-rails', '~> 1.12.4'
gem 'uglifier', '>= 1.3.0'
# jQuery & plugins
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-scrollto-rails',
    git: 'https://github.com/biosistemika/jquery-scrollto-rails'
gem 'hammerjs-rails'
gem 'js_cookie_rails' # Simple JS API for cookies
gem 'spinjs-rails'
gem 'autosize-rails' # jQuery autosize plugin

gem 'underscore-rails'
gem 'turbolinks', '~> 5.1.1'
gem 'sdoc', '~> 1.0', group: :doc
gem 'bcrypt', '~> 3.1.10'
gem 'logging', '~> 2.0.0'
gem 'aspector' # Aspect-oriented programming for Rails
gem 'rgl' # Graph framework for project diagram calculations
gem 'nested_form_fields'
gem 'ajax-datatables-rails', '~> 0.3.1'
gem 'commit_param_routing' # Enables different submit actions in the same form to route to different actions in controller
gem 'i18n-js', '~> 3.0' # Localization in javascript files
gem 'roo', '~> 2.7.1' # Spreadsheet parser
gem 'wicked_pdf', '~> 1.1.0'
gem 'silencer' # Silence certain Rails logs
gem 'wkhtmltopdf-heroku'
gem 'faker' # Generate fake data
gem 'auto_strip_attributes', '~> 2.1' # Removes unnecessary whitespaces from ActiveRecord or ActiveModel attributes
gem 'deface', '~> 1.0'
gem 'nokogiri', '~> 1.8.1' # HTML/XML parser
gem 'sneaky-save', git: 'https://github.com/einzige/sneaky-save'
gem 'rails_autolink', '~> 1.1', '>= 1.1.6'
gem 'delayed_paperclip',
    git: 'https://github.com/jrgifford/delayed_paperclip.git',
    ref: 'fcf574c'
gem 'rubyzip'
gem 'jbuilder' # JSON structures via a Builder-style DSL
gem 'activerecord-import'
gem 'scenic', '~> 1.4'

gem 'paperclip', '~> 5.3' # File attachment, image attachment library
gem 'aws-sdk', '~> 2'

gem 'delayed_job_active_record'
gem 'devise-async',
  git: 'https://github.com/mhfs/devise-async.git',
  branch: 'devise-4.x'

gem 'discard', '~> 1.0'

gem 'ruby-graphviz', '~> 1.2' # Graphviz for rails
gem 'tinymce-rails', '~> 4.7.13' # Rich text editor - SEE BELOW
# Any time you update tinymce-rails Gem, also update the cache_suffix parameter in
# sitewide/tiny_mce.js - to prevent browsers from loading old, cached .js
# TinyMCE files which might cause errors

gem 'base62' # Used for smart annotations
gem 'newrelic_rpm'
gem 'devise_security_extension',
    git: 'https://github.com/phatworx/devise_security_extension.git',
    ref: 'b2ee978'

# Permission helper Gem
gem 'canaid', git: 'https://github.com/biosistemika/canaid', branch: 'master'

group :development, :test do
  gem 'listen', '~> 3.0'
  gem 'byebug'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'awesome_print'
  gem 'rubocop', '>= 0.59.0', require: false
  gem 'scss_lint', require: false
  gem 'starscope', require: false
  gem 'bullet'
end

group :test do
  gem 'shoulda-matchers'
  gem 'cucumber-rails', '~> 1.5', require: false
  gem 'database_cleaner'
  gem 'capybara'
  gem 'capybara-email'
  gem 'poltergeist'
  gem 'phantomjs', require: 'phantomjs/poltergeist'
  gem 'simplecov', require: false
  gem 'json_matchers'
end

group :production do
  gem 'puma'
  gem 'rails_12factor'
  gem 'whacamole'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i(mingw mswin x64_mingw jruby)
