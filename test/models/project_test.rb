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

  should validate_length_of(:name)
    .is_at_least(Constants::NAME_MIN_LENGTH)
    .is_at_most(Constants::NAME_MAX_LENGTH)

  test 'should have non-blank name' do
    @project.name = ''
    assert @project.invalid?, 'Project with blank name returns valid? = true'
  end

  test 'should have team-wide unique name' do
    @project.name = @project2.name
    assert @project.invalid?,
           'Project with non-unique team-wide name returns valid? = true'
  end

  test 'should not have non-team-wide unique name' do
    @project.name = @project3.name
    assert @project.valid?,
           'Project with non-unique name in different teams ' \
           'returns valid? = false'
  end

  test 'should have default visibility & archived' do
    project = Project.new(name: 'sample project',
                          team_id: teams(:biosistemika).id)
    assert project.hidden?,
           'Project by default doesn\'t have visibility = hidden set'
    assert_not project.archived?, 'Project has default archived = true'
  end

  test 'should belong to team' do
    @project.team = nil
    assert_not @project.valid?, 'Project without team returns valid? = true'
    @project.team_id = 12321321
    assert_not @project.valid?, 'Project with team returls valid? = false'
  end

  test 'should have archived set' do
    project = Project.new(
      name: 'test project',
      visibility: 1,
      team_id: teams(:biosistemika).id
    )
    assert_archived_present(project)
    assert_active_is_inverse_of_archived(project)
  end

  test 'archiving should work' do
    user = users(:steve)
    project = Project.new(name: 'test project',
                          visibility: 1,
                          team_id: teams(:biosistemika).id)
    project.save
    archive_and_restore_action_test(project, user)
  end

  test 'where_attributes_like should work' do
    attributes_like_test(Project, :name, 'star')
  end
end
