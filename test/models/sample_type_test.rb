require 'test_helper'

class SampleTypeTest < ActiveSupport::TestCase
  def setup
    @sample_type = sample_types(:skin)
  end

  test "should validate with correct data" do
    assert @sample_type.valid?
  end

  test "should not validate without name" do
    @sample_type.name = ""
    assert_not @sample_type.valid?
    @sample_type.name = nil 
    assert_not @sample_type.valid?
  end

  test "should validate too long name value" do
    @sample_type.name *= 50
    assert_not @sample_type.valid?
  end

  test "should not validate without organization" do
    @sample_type.organization_id = 12321321
    assert_not @sample_type.valid?
    @sample_type.organization = nil
    assert_not @sample_type.valid?
  end
end
