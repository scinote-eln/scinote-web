# frozen_string_literal: true

source 'http://rubygems.org'

ruby '3.2.2'

gem 'bootsnap', require: false
gem 'devise', '~> 4.8.1'
gem 'devise_invitable'
gem 'pg', '~> 1.5'
gem 'pg_search' # PostgreSQL full text search
gem 'psych', '< 4.0'
gem 'rails', '~> 7.0.8'
gem 'recaptcha', require: 'recaptcha/rails'
gem 'sanitize'
gem 'sprockets-rails'
gem 'view_component'
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
gem 'jsonapi-renderer', '~> 0.2.2'
gem 'json-jwt'
gem 'jwt', '~> 1.5'
gem 'kaminari'
gem 'rack-attack'
gem 'rack-cors'

gem 'uglifier', '>= 1.3.0'

gem 'activerecord-import'
gem 'acts_as_list'
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
gem 'grover'
gem 'httparty', '~> 0.21.0'
gem 'i18n-js', '~> 3.6' # Localization in javascript files
gem 'jbuilder' # JSON structures via a Builder-style DSL
gem 'logging', '~> 2.0.0'
gem 'nested_form_fields'
gem 'nokogiri', '~> 1.16.2' # HTML/XML parser
gem 'noticed'
gem 'rails_autolink', '~> 1.1', '>= 1.1.6'
gem 'rgl' # Graph framework for project diagram calculations
gem 'roo', '~> 2.10.0' # Spreadsheet parser
gem 'rotp'
gem 'rqrcode', '~> 2.0' # QR code generator
gem 'rubyzip', '>= 2.3.0' # will load new rubyzip version
gem 'scenic', '~> 1.4'
gem 'sdoc', '~> 1.0', group: :doc
gem 'silencer' # Silence certain Rails logs
gem 'sneaky-save', git: 'https://github.com/einzige/sneaky-save'
gem 'turbolinks', '~> 5.2.0'
gem 'underscore-rails'
gem 'wicked_pdf'
gem 'zip-zip' # will load compatibility for old rubyzip API.

gem 'aws-sdk-lambda'
gem 'aws-sdk-rails'
gem 'aws-sdk-s3'
gem 'delayed_job_active_record'
gem 'devise-async',
    git: 'https://github.com/mhfs/devise-async.git',
    branch: 'devise-4.x'
gem 'image_processing'
gem 'img2zpl', git: 'https://github.com/scinote-eln/img2zpl'
gem 'rufus-scheduler'

gem 'discard'

gem 'graphviz'

gem 'cssbundling-rails'
gem 'jsbundling-rails'

gem 'tailwindcss-rails', '~> 2.0'

gem 'base62' # Used for smart annotations
gem 'newrelic_rpm'

# Permission helper Gem
gem 'canaid', git: 'https://github.com/scinote-eln/canaid'

group :development, :test do
  gem 'awesome_print'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bullet'
  gem 'byebug'
  gem 'factory_bot_rails'
  gem 'figaro'
  gem 'listen'
  gem 'overcommit'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'timecop'
end

group :test do
  gem 'capybara'
  gem 'capybara-email'
  gem 'cucumber-rails', require: false
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
