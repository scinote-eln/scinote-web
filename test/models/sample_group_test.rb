require 'test_helper'

class SampleGroupTest < ActiveSupport::TestCase
  def setup
    @sample_group = sample_groups(:blood)
  end

  test "should validate with correct data" do
    assert @sample_group.valid?
  end

  test "should not validate without name" do
    @sample_group.name = ""
    assert_not @sample_group.valid?
    @sample_group.name = nil
    assert_not @sample_group.valid?
  end

  test "should validate too long name value" do
    @sample_group.name *= 50
    assert_not @sample_group.valid? 
  end

  test "should validate without color because of default value" do
    @sample_group.color = ""
    assert_not @sample_group.valid?
    @sample_group.color = nil
    assert_not @sample_group.valid?
  end

  test "should validate too long color value" do
    @sample_group.color *= 7
    assert_not @sample_group.valid? 
  end

  test "should not validate without organization" do
    @sample_group.organization = nil
    assert_not @sample_group.valid?
  end
end
