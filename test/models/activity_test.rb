require 'test_helper'

class ActivityTest < ActiveSupport::TestCase
  test "should validate with correct data" do
    activity = Activity.new(
      type_of: 0,
      project: projects(:interfaces),
      my_module: my_modules(:sample_prep),
      user: users(:steve)
    )
    assert activity.valid?
  end

  test "should not validate without type_of" do
    activity = Activity.new(
      project: projects(:interfaces),
      my_module: my_modules(:sample_prep),
      user: users(:steve)
    )
    assert_not activity.valid?
  end

  test "should not validate with non existent project" do
    activity = Activity.new(
      type_of: 0,
      project_id: 1212,
      user: users(:steve)
    )
    assert_not activity.valid?
  end

  test "should not validate with non existent user" do
    activity = Activity.new(
      type_of: 0,
      project: projects(:interfaces),
      my_module: my_modules(:sample_prep),
      user_id: 123213123
    )
    assert_not activity.valid?
  end
end
