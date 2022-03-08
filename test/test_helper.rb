ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/reporters'
Minitest::Reporters.use!

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def assert_redirected_to_403
    assert_select "div.dialog div h1",
    { count: 1, text: I18n.t("forbidden.title") },
    "Not redirected to 403"
  end

  def assert_redirected_to_404
    assert_select "div.dialog div h1",
    { count: 1, text: I18n.t("not_found.title") },
    "Not redirected to 404"
  end
end

class ActionController::TestCase
  # Include Devise test helpers
  # (must not include them in ActiveSupport,
  # causes 'env' not found errors)
  include Devise::TestHelpers
end

# http://matchers.shoulda.io/docs/v3.1.1/
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :minitest
    with.test_framework :minitest_4

    # Choose a library:
    with.library :active_record
    with.library :active_model
    with.library :action_controller
    # Or, choose all of the above:
    with.library :rails
  end
end
