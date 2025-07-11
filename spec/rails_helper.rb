# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
require 'shoulda-matchers'
require 'database_cleaner'
require 'devise'
require_relative 'support/controller_macros'
ENV['RAILS_ENV'] = 'test'

ENV['CORE_API_V1_ENABLED'] = 'true'
ENV['CORE_API_V2_ENABLED'] = 'true'
ENV['EXPORT_ALL_LIMIT_24_HOURS'] = '3'

require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migration
begin
  ActiveRecord::Migration.check_all_pending!
rescue ActiveRecord::PendingMigrationError => e
  abort(e.message)
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start

    # project creation now requires an owner role to be present, as it assigns it to creator
    # so we must ensure it always exists
    UserRole.exists?(name: I18n.t('user_roles.predefined.owner')) || UserRole.owner_role.save!
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.before(:all) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:all) do
    DatabaseCleaner.start
    # project creation now requires an owner role to be present, as it assigns it to creator
    # so we must ensure it always exists
    UserRole.exists?(name: I18n.t('user_roles.predefined.owner')) || UserRole.owner_role.save!
  end

  config.after(:all) do
    DatabaseCleaner.clean
  end

  Delayed::Worker.delay_jobs = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # includes FactoryBot in rspec
  config.include FactoryBot::Syntax::Methods
  FactoryBot::SyntaxRunner.class_eval do
    include ActionDispatch::TestProcess
  end
  # Devise
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include ApiHelper, type: :controller
  config.include ApiHelper, type: :request
  config.extend ControllerMacros, type: :controller
  config.include PermissionHelpers

  config.filter_run_excluding broken: true
end

# config shoulda matchers to work with rspec
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
