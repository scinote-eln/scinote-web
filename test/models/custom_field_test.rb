require 'test_helper'

class CustomFieldTest < ActiveSupport::TestCase
  def setup
    @custom_field = custom_fields(:volume)
  end

  test "should validate with correct data" do
    assert @custom_field.valid?
  end

  test "should not validate without name" do
    @custom_field.name = ""
    assert_not @custom_field.valid?
    @custom_field.name = nil
    assert_not @custom_field.valid?
  end

  test "should not validate with too long name" do
    @custom_field.name = "n" * 51
    assert_not @custom_field.valid?
  end

  test "should not validate with non existent user" do
    @custom_field.user_id = 11231231
    assert_not @custom_field.valid?
    @custom_field.user = nil
    assert_not @custom_field.valid?
  end

  test "should not validate with non existent organization" do
    @custom_field.organization_id = 1231231
    assert_not @custom_field.valid?
    @custom_field.organization = nil
    assert_not @custom_field.valid?
  end
end
