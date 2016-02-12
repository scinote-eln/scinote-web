require 'test_helper'

class UserOrganizationTest < ActiveSupport::TestCase
  def setup
    @user_org = user_organizations(:one)
  end

# Test role attribute
  test "should not save user organization without role" do
    assert_not user_organizations(:without_role).save,
      "Saved user organization without role"
  end

  test "should have default role" do
    assert @user_org.normal_user?,
      "User organization does not have default normal_user role"
  end

  test "should set valid role values" do
    assert_nothing_raised(ArgumentError,
      "User organization role was set with invalid role value") {
      @user_org.role = 0
      @user_org.role = 1
      @user_org.role = 2
      @user_org.role = "guest"
      @user_org.role = "normal_user"
      @user_org.role = "admin"
    }
  end

  test "should not have undefined role" do
    assert_raises(ArgumentError,
      "User organization role can not be set to undefined numeric role value") {
      @user_org.role = 5
    }
    assert_raises(ArgumentError,
      "User organization role can not be set to undefined role value") {
      @user_org.role = "gatekeeper"
    }
  end

# Test user attribute
  test "should not save user organization without user" do
    assert_not user_organizations(:without_user).save,
      "Saved user organization without user"
  end

  test "should not associate unexisting user" do
    assert_raises(ActiveRecord::RecordInvalid,
      "User organization saved unexisting user association") {
      user_organizations(:with_invalid_user).save!
    }
  end

# Test organization attribute
  test "should not save user organization without organization" do
    assert_not user_organizations(:without_organization).save,
      "Saved user organization without organization"
  end

  test "should not associate unexisting organization" do
    assert_raises(ActiveRecord::RecordInvalid,
      "User organization saved unexisting organization association") {
      user_organizations(:with_invalid_organization).save!
    }
  end
end
