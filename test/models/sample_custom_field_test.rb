require 'test_helper'

class SampleCustomFieldTest < ActiveSupport::TestCase
  def setup
    @sample_custom_field = sample_custom_fields(:one)
  end

  test "should validate with correct data" do
    assert @sample_custom_field.valid?
  end

  test "should not validate without value" do
    @sample_custom_field.value = ""
    assert_not @sample_custom_field.valid?
    @sample_custom_field.value = nil
    assert_not @sample_custom_field.valid?
  end

  test "should validate to long value length" do
    @sample_custom_field.value *= 100
    assert_not @sample_custom_field.valid?
  end

  test "should not validate with non existent custom field" do
    @sample_custom_field.custom_field_id = 123421321
    assert_not @sample_custom_field.valid?
    @sample_custom_field.custom_field = nil
    assert_not @sample_custom_field.valid?
  end

  test "should not validate with non existent sample" do
    @sample_custom_field.sample_id = 12313213
    assert_not @sample_custom_field.valid?
    @sample_custom_field.sample = nil
    assert_not @sample_custom_field.valid?
  end
end
