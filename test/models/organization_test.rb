require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  def setup
    @org = organizations(:test)
  end

  should validate_length_of(:name)
    .is_at_least(NAME_MIN_LENGTH)
    .is_at_most(NAME_MAX_LENGTH)

  should validate_length_of(:description)
    .is_at_most(TEXT_MAX_LENGTH)

  test "should validate organization default values" do
    assert @org.valid?
  end

  test "should have non-blank name" do
    @org.name = ""
    assert @org.invalid?, "Organization with blank name returns valid? = true"
  end

  test "should have space_taken present" do
    @org.space_taken = nil
    assert @org.invalid?, "Organization without space_taken returns valid? = true"
  end

  test "space_taken_defaults_to_value" do
    org = Organization.new
    assert_equal MINIMAL_ORGANIZATION_SPACE_TAKEN, org.space_taken
  end

  test "should save log message" do
    message = "This is test message"
    @org.log(message)
    log_message = Log.last.message[26..-1]
    assert_equal log_message, message
  end

  test "should open spreadsheet file" do
    skip
  end
end
