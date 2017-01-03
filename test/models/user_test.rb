require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:john)
    @user2 = users(:steve)
    @org = organizations(:biosistemika)
  end

  should validate_presence_of(:full_name)
  should validate_length_of(:full_name).is_at_most(Constants::NAME_MAX_LENGTH)
  should validate_presence_of(:initials)
  should validate_length_of(:initials)
    .is_at_most(Constants::USER_INITIALS_MAX_LENGTH)

# Test password attribute
  test "should have non-blank password" do
    @user.password = ""
    assert @user.invalid?, "User with blank email is not valid"
  end

  test "should have password with at least 8 characters" do
    @user.password = "1234567"
    assert @user.invalid?, "User with too short password is not valid"
    @user.password = "12345678"
    assert_not @user.invalid?, "User with password longer than 7 characters is valid"
  end

# Test email attribute
  test "should have non-blank email" do
    @user.email = ""
    assert @user.invalid?, "User with blank email is not valid"
  end

  test "should have unique email" do
    @user.email = @user2.email
    assert @user.invalid?, "User with non-unique email in not valid"
  end

# Test methods
  test "should get projects for organization" do
    org_projects = @user2.projects_by_orgs(@org.id)
    assert_equal 1, org_projects.size, "Projects are grouped into one organization"
    assert_equal 4, org_projects[@org].size, "Organization group has many projects"
  end

  test "should get archived projects for organization" do
    org_projects = @user2.projects_by_orgs(@org.id, nil, true)
    assert_equal 1, org_projects.size, "Projects are grouped into one organization"
    assert_equal 2, org_projects[@org].size, "Organization group has many projects"
  end

  test "should sort projects by create timestamp ascending" do
    org_projects = @user2.projects_by_orgs(@org.id, "old")
    first_project = projects(:interfaces)
    last_project = projects(:z_project)
    assert_equal first_project, org_projects[@org].first
    assert_equal last_project, org_projects[@org].last
  end

  test "should sort projects by create timestamp descending" do
    org_projects = @user2.projects_by_orgs(@org.id)
    first_project = projects(:z_project)
    last_project = projects(:interfaces)
    assert_equal first_project, org_projects[@org].first
    assert_equal last_project, org_projects[@org].last
  end

  test "should sort projects by project name ascending" do
    org_projects = @user2.projects_by_orgs(@org.id, "atoz")
    first_project = projects(:a_project)
    last_project = projects(:z_project)
    assert_equal first_project, org_projects[@org].first
    assert_equal last_project, org_projects[@org].last
  end

  test "should sort projects by project name descending" do
    org_projects = @user2.projects_by_orgs(@org.id, "ztoa")
    first_project = projects(:z_project)
    last_project = projects(:a_project)
    assert_equal first_project, org_projects[@org].first
    assert_equal last_project, org_projects[@org].last
  end

  test "should sort archived projects by create timestamp ascending" do
    org_projects = @user2.projects_by_orgs(@org.id, "old", true)
    first_project = projects(:a_archived_project)
    last_project = projects(:z_archived_project)
    assert_equal first_project, org_projects[@org].first
    assert_equal last_project, org_projects[@org].last
  end

  test "should sort archived projects by create timestamp descending" do
    org_projects = @user2.projects_by_orgs(@org.id, nil, true)
    first_project = projects(:z_archived_project)
    last_project = projects(:a_archived_project)
    assert_equal first_project, org_projects[@org].first
    assert_equal last_project, org_projects[@org].last
  end

  test "should sort archived projects by project name ascending" do
    org_projects = @user2.projects_by_orgs(@org.id, "atoz", true)
    first_project = projects(:a_archived_project)
    last_project = projects(:z_archived_project)
    assert_equal first_project, org_projects[@org].first
    assert_equal last_project, org_projects[@org].last
  end

  test "should sort archived projects by project name descending" do
    org_projects = @user2.projects_by_orgs(@org.id, "ztoa", true)
    first_project = projects(:z_archived_project)
    last_project = projects(:a_archived_project)
    assert_equal first_project, org_projects[@org].first
    assert_equal last_project, org_projects[@org].last
  end

  test "should get last activities" do
    last_activities = @user2.last_activities(0)
    first_activity = activities(:twelve)
    last_activity = activities(:three)
    assert_equal 10, last_activities.size
    assert_equal first_activity, last_activities.first
    assert_equal last_activity, last_activities.last
  end

  test "should get specified number of last activities" do
    last_activities = @user2.last_activities(0, 4)
    first_activity = activities(:twelve)
    last_activity = activities(:nine)
    assert_equal 4, last_activities.size
    assert_equal first_activity, last_activities.first
    assert_equal last_activity, last_activities.last
  end

  test "should allow to change time zone" do
    assert @user.valid?
    @user.time_zone = "Ljubljana"
    assert @user.valid?
  end

  test "should validate time zone value" do
    assert @user.valid?
    @user.time_zone = "Very Strange Place on Earth"
    assert_not @user.valid?
  end

  test "should check if time zone value is set" do
    assert @user.valid?
    @user.time_zone = nil
    assert_not @user.valid?
  end
end
