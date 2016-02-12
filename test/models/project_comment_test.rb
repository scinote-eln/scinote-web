require 'test_helper'

class ProjectCommentTest < ActiveSupport::TestCase
  def setup
    @project_comment = project_comments(:test)
    @project = @project_comment.project
    @comment = @project_comment.comment
  end

  test "should validate with correct data" do
    assert @project_comment.valid?
  end

  test "should not validate with non existent comment id" do
    @project_comment.comment_id = 2343434
    assert_not @project_comment.valid?
    @project_comment.comment = nil
    assert_not @project_comment.valid?
  end

  test "should not validate with non existent project id" do
    @project_comment.project_id = 1223232323
    assert_not @project_comment.valid?
    @project_comment.project = nil
    assert_not @project_comment.valid?
  end

  test "should validate for project/comment uniqueness" do
    project_comment = ProjectComment.new(
      project: @project, comment: @comment)
    assert_not project_comment.save
  end

  test "should have association project -> comment" do
    project = projects(:dummy)
    project.comments << @comment
    assert_equal @comment, Project.find(project.id).comments.first, "There is no association between project -> comment."
  end
end
