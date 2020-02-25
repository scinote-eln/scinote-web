# frozen_string_literal: true

source 'http://rubygems.org'

ruby '2.6.4'

gem 'bootsnap', require: false
gem 'bootstrap-sass', '~> 3.4.1'
gem 'bootstrap_form', '~> 2.7.0'
gem 'devise', '~> 4.7.1'
gem 'devise_invitable'
gem 'figaro'
gem 'pg', '~> 1.1'
gem 'pg_search' # PostgreSQL full text search
gem 'rails', '~> 6.0.0'
gem 'recaptcha', require: 'recaptcha/rails'
gem 'sanitize', '~> 5.0'
gem 'sassc-rails'
gem 'simple_token_authentication', '~> 1.16.0' # Token authentication for Devise
gem 'webpacker', '~> 4.0.0'
gem 'yomu', git: 'https://github.com/biosistemika/yomu', branch: 'master'

# Gems for OAuth2 subsystem
gem 'doorkeeper', '>= 4.6'
gem 'omniauth'
gem 'omniauth-azure-activedirectory'
gem 'omniauth-linkedin-oauth2'

# TODO: remove this when omniauth gem resolves CVE issues
# Prevents CVE-2015-9284 (https://github.com/omniauth/omniauth/wiki/FAQ#cve-2015-9284-warnings)
gem 'omniauth-rails_csrf_protection', '~> 0.1'

# Gems for API implementation
gem 'active_model_serializers', '~> 0.10.7'
gem 'json-jwt'
gem 'jsonapi-renderer', '~> 0.2.2'
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
gem 'caracal-rails' # Build docx report
gem 'commit_param_routing' # Enables different submit actions in the same form
gem 'deface', '~> 1.0'
gem 'down', '~> 5.0'
gem 'faker' # Generate fake data
gem 'fastimage' # Light gem to get image resolution
gem 'httparty', '~> 0.13.1'
gem 'i18n-js', '~> 3.0' # Localization in javascript files
gem 'jbuilder' # JSON structures via a Builder-style DSL
gem 'logging', '~> 2.0.0'
gem 'nested_form_fields'
gem 'nokogiri', '~> 1.10.8' # HTML/XML parser
gem 'rails_autolink', '~> 1.1', '>= 1.1.6'
gem 'rgl' # Graph framework for project diagram calculations
gem 'roo', '~> 2.8.2' # Spreadsheet parser
gem 'rubyzip'
gem 'scenic', '~> 1.4'
gem 'sdoc', '~> 1.0', group: :doc
gem 'silencer' # Silence certain Rails logs
gem 'sneaky-save', git: 'https://github.com/einzige/sneaky-save'
gem 'turbolinks', '~> 5.1.1'
gem 'underscore-rails'
gem 'wicked_pdf', '~> 1.4.0'
gem 'wkhtmltopdf-heroku', '2.12.5'

gem 'aws-sdk-rails'
gem 'aws-sdk-s3'
gem 'delayed_job_active_record'
gem 'devise-async',
    git: 'https://github.com/mhfs/devise-async.git',
    branch: 'devise-4.x'
gem 'image_processing', '~> 1.2'
gem 'rufus-scheduler', '~> 3.5'

gem 'discard', '~> 1.0'

gem 'ruby-graphviz', '~> 1.2' # Graphviz for rails
gem 'tinymce-rails', '~> 4.9.3' # Rich text editor - SEE BELOW
# Any time you update tinymce-rails Gem, also update the cache_suffix parameter
# in sitewide/tiny_mce.js - to prevent browsers from loading old, cached .js
# TinyMCE files which might cause errors

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
  gem 'rubocop', '>= 0.75.0', require: false
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
