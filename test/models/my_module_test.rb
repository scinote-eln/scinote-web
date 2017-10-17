require 'test_helper'
require 'helpers/archivable_model_test_helper'
require 'helpers/searchable_model_test_helper'

class MyModuleTest < ActiveSupport::TestCase
  include ArchivableModelTestHelper
  include SearchableModelTestHelper

  def setup
    @my_module = my_modules(:list_of_samples)
  end

  should validate_length_of(:name)
    .is_at_least(Constants::NAME_MIN_LENGTH)
    .is_at_most(Constants::NAME_MAX_LENGTH)

  test "should validate valid module object" do
    assert @my_module.valid?
  end

  test "should not validate without name" do
    @my_module.name = ""
    assert_not @my_module.valid?
    @my_module.name = nil
    assert_not @my_module.valid?
  end

  test "should not validate with non existing experiment" do
    @my_module.experiment_id = 123123
    assert_not @my_module.valid?
    @my_module.experiment = nil
    assert_not @my_module.valid?
  end

  test "should not validate with non existing module group, when group is set" do
    @my_module.my_module_group_id = 23123
    assert_not @my_module.valid?
  end

  test "should default to 0, when x and y not set" do
    assert_equal 0, @my_module.x
    assert_equal 0, @my_module.y
  end

  test "should default to 0, when workflow_order not set" do
    assert_equal 0, @my_module.workflow_order
  end

  test "should have archived set" do
    assert_archived_present(@my_module)
    assert_active_is_inverse_of_archived(@my_module)
  end

  test "archiving should work" do
    user = users(:steve)
    archive_and_restore_action_test(@my_module, user)
  end

  test "where_attributes_like should work" do
    attributes_like_test(MyModule, [:name, :description], "sample")
  end

  test "should get unassigned users" do
    unassigned_users = @my_module.unassigned_users
    assert_equal 1, unassigned_users.size
    @my_module.users << unassigned_users.first
    assert @my_module.save
    unassigned_users = @my_module.unassigned_users
    assert_equal 0, unassigned_users.size
  end

  test "should get unassigned samples" do
    unassigned_samples = @my_module.unassigned_samples
    assert_equal 5, unassigned_samples.size
    @my_module.samples << unassigned_samples.first
    assert @my_module.save
    unassigned_samples = @my_module.unassigned_samples
    assert_equal 4, unassigned_samples.size
  end

  test "should get unassigned tags" do
    unassigned_tags = @my_module.unassigned_tags
    assert_equal 2, unassigned_tags.size
    @my_module.tags << unassigned_tags.first
    assert @my_module.save
    unassigned_tags = @my_module.unassigned_tags
    assert_equal 1, unassigned_tags.size
  end

  test "should get last comments" do
    skip
  end

  test "should get last activities" do
    skip
  end

  test "should get specified number of samples" do
    skip
  end

  test "should get completed steps" do
    skip
  end

  test "should check if project is overdue" do
    assert @my_module.is_overdue?
    @my_module.due_date = "2025-12-04 12:00:00"
    assert_not @my_module.is_overdue?
  end

  test "should check if overdue in days" do
    days_diff = 12
    @my_module.due_date = DateTime.now - days_diff
    assert_equal days_diff, @my_module.overdue_for_days
  end

  test "should check if is due date one day prior" do
    @my_module.due_date = DateTime.now + 1.hour
    assert @my_module.is_one_day_prior?
  end

  test "should check if due date is due in specified days" do
    @my_module.due_date = DateTime.now + 1.hour
    assert @my_module.is_due_in?(DateTime.now, 2.hours)
  end

  test "should get archived results" do
    archived_results = @my_module.archived_results
    assert_equal 1, archived_results.size
  end

  test "should get downstream modules" do
    skip
  end

  test "should get samples in JSON format" do
    skip
  end

  test "should deep clone module" do
    skip
  end
end
