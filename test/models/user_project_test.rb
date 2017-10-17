require 'test_helper'

class UserProjectTest < ActiveSupport::TestCase
  def setup
    @user_proj = user_projects(:one)
  end

# Test role attribute
  test "should not save user project without role" do
    assert_not user_projects(:without_role).save,
      "Saved user project without role"
  end

  test "should have default role" do
    assert @user_proj.owner?, "User project does not have default owner role"
  end

  test "should set valid role values" do
    assert_nothing_raised(ArgumentError,
      "User project role was set with invalid role value") {
      @user_proj.role = 0
      @user_proj.role = 1
      @user_proj.role = 2
      @user_proj.role = 3
      @user_proj.role = "owner"
      @user_proj.role = "normal_user"
      @user_proj.role = "technician"
      @user_proj.role = "viewer"
    }
  end

  test "should not have undefined role" do
    assert_raises(ArgumentError,
      "User project role can not be set to undefined numeric role value") {
      @user_proj.role = 5
    }
    assert_raises(ArgumentError,
      "User project role can not be set to undefined role value") {
      @user_proj.role = "gatekeeper"
    }
  end

# Test user attribute
  test "should not save user project without user" do
    assert_not user_projects(:without_user).save,
      "Saved user project without user"
  end

  test "should not associate unexisting user" do
    assert_raises(ActiveRecord::RecordInvalid,
      "User project saved unexisting user association") {
      user_projects(:with_invalid_user).save!
    }
  end

# Test project attribute
  test "should not save user project without project" do
    assert_not user_projects(:without_project).save,
      "Saved user project without project"
  end

  test "should not associate unexisting project" do
    assert_raises(ActiveRecord::RecordInvalid,
      "User project saved unexisting project association") {
      user_projects(:with_invalid_project).save!
    }
  end

# Test destroy_associations method
  test "should unassign user from all projects' modules" do
    user_project = @user_proj
    user = user_project.user

    # Test associations before destroy
    assert_equal 1, my_modules(:sample_prep)
      .user_my_modules.select { |um| um.user == user }.count
    assert_equal 1, my_modules(:rna_test)
      .user_my_modules.select { |um| um.user == user }.count

    assert user_project.destroy

    # Test associations after destroy
    experiments(:philadelphia).my_modules.each do |my_module|
      assert_equal 0, my_module.user_my_modules
        .select { |um| um.user == user }.count
    end
  end
end
