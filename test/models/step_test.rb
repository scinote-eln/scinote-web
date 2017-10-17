require 'test_helper'
require 'helpers/searchable_model_test_helper'

class StepTest < ActiveSupport::TestCase
  include SearchableModelTestHelper

  def setup
    @step = steps(:test2)
  end

  test "should not validate without name" do
    assert @step.valid?
    @step.name = ""
    assert_not @step.valid?
  end

  test "should not validate with to long name" do
    assert @step.valid?
    @step.name = 'a' * 256
    assert_not @step.valid?
  end

  test "should validate without description" do
    assert @step.valid?
    @step.description = ""
    assert @step.valid?
  end

  test "should not validate with to long description" do
    assert @step.valid?
    @step.name = 'a' * 4001
    assert_not @step.valid?
  end

  test "should not validate without position" do
    assert @step.valid?
    @step.position = nil
    assert_not @step.valid?
  end

  test "should not validate without completed" do
    assert @step.valid?
    @step.completed = nil
    assert_not @step.valid?
  end

  test "should not validate with completed=true and completed not present" do
    assert @step.valid?
    @step.completed = true
    assert_not @step.valid?
  end

  test "should validate with completed=true and completed present" do
    assert @step.valid?
    @step.completed = true
    @step.completed_on = "2015-07-21"
    assert @step.valid?
  end

  test "should validate with non existent user" do
    assert @step.valid?
    @step.user_id = 123123
    assert_not @step.valid?
    @step.user = nil
    assert_not @step.valid?
   end

  test "should not validate with non existing protocol" do
    assert @step.valid?
    @step.protocol_id = 12312321
    assert_not @step.valid?
    @step.protocol = nil
    assert_not @step.valid?
   end

  test "where_attributes_like should work" do
    attributes_like_test(Result, :name, "mrna")
  end


# Testing last_comments method

  test "should get last comments" do
    last_comments = steps(:test2).last_comments
    first_comment = comments(:test_step_comment_24)
    last_comment = comments(:test_step_comment_5)
    assert_equal 20, last_comments.size
    assert_equal first_comment, last_comments.last
    assert_equal last_comment, last_comments.first
  end

  # Not possible to test with fixtures and random id values
  test "should get last comments before specific comment" do
  end

  test "should get last comments of specified length" do
    last_comments = steps(:test2).last_comments(0, 5)
    first_comment = comments(:test_step_comment_24)
    last_comment = comments(:test_step_comment_20)
    assert_equal 5, last_comments.size
    assert_equal first_comment, last_comments.last
    assert_equal last_comment, last_comments.first
  end


# Testing destroy_activity callback

  test "should create new activity for step_remove" do
    last_activity = Activity.last
    user = users(:jlaw)
    assert @step.destroy(user)
    created_activity = Activity.last
    assert_not_equal last_activity, created_activity
    assert_equal "destroy_step", created_activity.type_of
    assert_equal user, created_activity.user
  end


# Testing save method

  # TODO check last_modified_by for step tables, assets and checklists
end
