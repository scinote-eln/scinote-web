# frozen_string_literal: true

source 'http://rubygems.org'

ruby '2.7.6'

gem 'bootsnap', require: false
gem 'bootstrap-sass', '~> 3.4.1'
gem 'bootstrap_form', '~> 2.7.0'
gem 'devise', '~> 4.8.1'
gem 'devise_invitable'
gem 'figaro'
gem 'pg', '~> 1.1'
gem 'pg_search' # PostgreSQL full text search
gem 'rails', '~> 6.1.5'
gem 'psych', '< 4.0'
gem 'view_component', require: 'view_component/engine'
gem 'recaptcha', require: 'recaptcha/rails'
gem 'sanitize'
gem 'sassc-rails'
gem 'yomu', git: 'https://github.com/scinote-eln/yomu', branch: 'master'

# Gems for OAuth2 subsystem
gem 'doorkeeper', '>= 4.6'
gem 'omniauth', '~> 2.1'
gem 'omniauth-azure-activedirectory-v2'
gem 'omniauth-linkedin-oauth2'
gem 'omniauth-okta', git: 'https://github.com/scinote-eln/omniauth-okta', branch: 'org_auth_server_support'
gem 'omniauth-rails_csrf_protection', '~> 1.0'

# Gems for API implementation
gem 'active_model_serializers', '~> 0.10.7'
gem 'json-jwt'
gem 'jsonapi-renderer', '~> 0.2.2'
gem 'jwt', '~> 1.5'
gem 'kaminari'
gem 'rack-attack'
gem 'rack-cors'

# JS datetime library, requirement of datetime picker
gem 'momentjs-rails', '~> 2.17.1'
# JS datetime picker
gem 'bootstrap3-datetimepicker-rails', '~> 4.17'
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
# gem 'caracal'
gem 'caracal',
    git: 'https://github.com/scinote-eln/caracal.git', branch: 'rubyzip2' # Build docx report
gem 'deface', '~> 1.9'
gem 'down', '~> 5.0'
gem 'faker' # Generate fake data
gem 'fastimage' # Light gem to get image resolution
gem 'httparty', '~> 0.21.0'
gem 'i18n-js', '~> 3.6' # Localization in javascript files
gem 'jbuilder' # JSON structures via a Builder-style DSL
gem 'logging', '~> 2.0.0'
gem 'nested_form_fields'
gem 'nokogiri', '~> 1.14.3' # HTML/XML parser
gem 'rails_autolink', '~> 1.1', '>= 1.1.6'
gem 'rgl' # Graph framework for project diagram calculations
gem 'roo', '~> 2.8.2' # Spreadsheet parser
gem 'rotp'
gem 'rqrcode', '~> 2.0' # QR code generator
gem 'rubyzip', '>= 2.3.0' # will load new rubyzip version
gem 'zip-zip' # will load compatibility for old rubyzip API.
gem 'scenic', '~> 1.4'
gem 'sdoc', '~> 1.0', group: :doc
gem 'silencer' # Silence certain Rails logs
gem 'sneaky-save', git: 'https://github.com/einzige/sneaky-save'
gem 'turbolinks', '~> 5.1.1'
gem 'underscore-rails'
gem 'wicked_pdf'

gem 'aws-sdk-lambda'
gem 'aws-sdk-rails'
gem 'aws-sdk-s3'
gem 'delayed_job_active_record'
gem 'devise-async',
    git: 'https://github.com/mhfs/devise-async.git',
    branch: 'devise-4.x'
gem 'image_processing', '~> 1.12'
gem 'img2zpl', git: 'https://github.com/scinote-eln/img2zpl'
gem 'rufus-scheduler', '~> 3.5'

gem 'discard', '~> 1.0'

gem 'graphviz'

gem 'jsbundling-rails'

gem 'tailwindcss-rails', '~> 2.0'

gem 'base62' # Used for smart annotations
gem 'newrelic_rpm'

# Permission helper Gem
gem 'canaid', git: 'https://github.com/biosistemika/canaid', branch: 'rails_6'

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
  gem 'rspec-rails', '>= 4.0.0.beta2'
  gem 'rubocop', '= 0.83.0', require: false
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'timecop'
end

group :test do
  gem 'capybara'
  gem 'capybara-email'
  gem 'cucumber-rails', '~> 1.8', require: false
  gem 'database_cleaner'
  gem 'json_matchers'
  gem 'selenium-webdriver'
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
