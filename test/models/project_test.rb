require 'test_helper'
require 'helpers/archivable_model_test_helper'
require 'helpers/searchable_model_test_helper'

class ProjectTest < ActiveSupport::TestCase
  include ArchivableModelTestHelper
  include SearchableModelTestHelper

  def setup
    @project = projects(:test1)
    @project2 = projects(:test2)
    @project3 = projects(:test3)
  end

  test "should have non-blank name" do
    @project.name = ""
    assert @project.invalid?, "Project with blank name returns valid? = true"
  end

  test "should have short name" do
    @project.name = "k" * 31
    assert @project.invalid?, "Project with name too long returns valid? = true"
  end

  test "should have long enough name" do
    @project.name = "k" * 3
    assert @project.invalid?, "Project with name too short returns valid? = true"
  end

  test "should have organization-wide unique name" do
    @project.name = @project2.name
    assert @project.invalid?, "Project with non-unique organization-wide name returns valid? = true"
  end

  test "should not have non-organization-wide unique name" do
    @project.name = @project3.name
    assert @project.valid?, "Project with non-unique name in different organizations returns valid? = false"
  end

  test "should have default visibility & archived" do
    project = Project.new(
      name: "sample project",
      organization_id: organizations(:biosistemika).id)
    assert project.hidden?, "Project by default doesn't have visibility = hidden set"
    assert_not project.archived?, "Project has default archived = true"
  end

  test "should belong to organization" do
    @project.organization = nil
    assert_not @project.valid?, "Project without organization returns valid? = true"
    @project.organization_id = 12321321
    assert_not @project.valid?, "Project with organization returls valid? = false"
  end

  test "should have archived set" do
    project = Project.new(
      name: "test project",
      visibility: 1,
      organization_id: organizations(:biosistemika).id
    )
    assert_archived_present(project)
    assert_active_is_inverse_of_archived(project)
  end

  test "archiving should work" do
    user = users(:steve)
    project = Project.new(
      name: "test project",
      visibility: 1,
      organization_id: organizations(:biosistemika).id,
    )
    project.save
    archive_and_restore_action_test(project, user)
  end

  test "where_attributes_like should work" do
    attributes_like_test(Project, :name, "star")
  end
end
