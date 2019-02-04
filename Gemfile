# frozen_string_literal: true

source 'http://rubygems.org'

ruby '2.4.5'

gem 'bootstrap-sass', '~> 3.3.7'
gem 'bootstrap_form'
gem 'devise', '~> 4.3.0'
gem 'devise_invitable'
gem 'figaro'
gem 'pg', '~> 0.18'
gem 'pg_search' # PostgreSQL full text search
gem 'rails', '5.1.6'
gem 'recaptcha', require: 'recaptcha/rails'
gem 'sanitize', '~> 4.4'
gem 'sass-rails', '~> 5.0.6'
gem 'simple_token_authentication', '~> 1.15.1' # Token authentication for Devise
gem 'webpacker', '~> 2.0'
gem 'yomu'

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
gem 'autosize-rails' # jQuery autosize plugin
gem 'hammerjs-rails'
gem 'jquery-rails'
gem 'jquery-scrollto-rails',
    git: 'https://github.com/biosistemika/jquery-scrollto-rails'
gem 'jquery-ui-rails'
gem 'js_cookie_rails' # Simple JS API for cookies
gem 'spinjs-rails'

gem 'activerecord-import'
gem 'ajax-datatables-rails', '~> 0.3.1'
gem 'aspector' # Aspect-oriented programming for Rails
gem 'auto_strip_attributes', '~> 2.1' # Removes unnecessary whitespaces AR
gem 'bcrypt', '~> 3.1.10'
gem 'commit_param_routing' # Enables different submit actions in the same form
gem 'deface', '~> 1.0'
gem 'delayed_paperclip',
    git: 'https://github.com/jrgifford/delayed_paperclip.git',
    ref: 'fcf574c'
gem 'faker' # Generate fake data
gem 'httparty'
gem 'i18n-js', '~> 3.0' # Localization in javascript files
gem 'jbuilder' # JSON structures via a Builder-style DSL
gem 'logging', '~> 2.0.0'
gem 'nested_form_fields'
gem 'nokogiri', '~> 1.8.1' # HTML/XML parser
gem 'rails_autolink', '~> 1.1', '>= 1.1.6'
gem 'rgl' # Graph framework for project diagram calculations
gem 'roo', '~> 2.7.1' # Spreadsheet parser
gem 'rubyzip'
gem 'scenic', '~> 1.4'
gem 'sdoc', '~> 1.0', group: :doc
gem 'silencer' # Silence certain Rails logs
gem 'sneaky-save', git: 'https://github.com/einzige/sneaky-save'
gem 'turbolinks', '~> 5.1.1'
gem 'underscore-rails'
gem 'wicked_pdf', '~> 1.1.0'
gem 'wkhtmltopdf-heroku'

gem 'aws-sdk', '~> 2'
gem 'paperclip', '~> 5.3' # File attachment, image attachment library

gem 'delayed_job_active_record'
gem 'devise-async',
    git: 'https://github.com/mhfs/devise-async.git',
    branch: 'devise-4.x'

gem 'discard', '~> 1.0'

gem 'ruby-graphviz', '~> 1.2' # Graphviz for rails
gem 'tinymce-rails', '~> 4.7.13' # Rich text editor - SEE BELOW
# Any time you update tinymce-rails Gem, also update the cache_suffix parameter
# in sitewide/tiny_mce.js - to prevent browsers from loading old, cached .js
# TinyMCE files which might cause errors

gem 'base62' # Used for smart annotations
gem 'devise_security_extension',
    git: 'https://github.com/phatworx/devise_security_extension.git',
    ref: 'b2ee978'
gem 'newrelic_rpm'

# Permission helper Gem
gem 'canaid', git: 'https://github.com/biosistemika/canaid', branch: 'master'

group :development, :test do
  gem 'awesome_print'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bullet'
  gem 'byebug'
  gem 'factory_bot_rails'
  gem 'listen', '~> 3.0'
  gem 'overcommit'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'rubocop', '>= 0.59.0', require: false
  gem 'scss_lint', require: false
  gem 'starscope', require: false
  gem 'timecop'
end

group :test do
  gem 'capybara'
  gem 'capybara-email'
  gem 'cucumber-rails', '~> 1.5', require: false
  gem 'database_cleaner'
  gem 'json_matchers'
  gem 'phantomjs', require: 'phantomjs/poltergeist'
  gem 'poltergeist'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'webmock'
end

group :production do
  gem 'puma'
  gem 'rails_12factor'
  gem 'whacamole'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i(mingw mswin x64_mingw jruby)
