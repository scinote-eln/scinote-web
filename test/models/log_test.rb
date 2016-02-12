require 'test_helper'

class LogTest < ActiveSupport::TestCase

  def setup
    @log =  logs(:one)
  end

  test "should validate log with valid data" do
    assert @log.valid?
  end

  test "should have non-blank message" do
    @log.message = ""
    assert @log.invalid?, "Log with blank message returns valid? = true"
    @log.message = nil
    assert @log.invalid?, "Log with nil message returns valid? = true"
  end

  test "should have organization" do
    @log.organization_id = 12321321
    assert @log.invalid?, "Log without organization returns valid? = true"
    @log.organization = nil
    assert @log.invalid?, "Log without organization returns valid? = true"
    @log.organization = Organization.new
    assert @log.valid?, "Log with organization returns valid? = false"
  end
end
