require 'test_helper'

class StepCommentTest < ActiveSupport::TestCase

  def setup
    @step = steps(:empty)
    @step_comment = step_comments(:test)
    @comment = comments(:test)
  end

  test "should validate with correct data" do
    assert @step_comment.valid?
  end

  test "should not validate with non existent comment id" do
    @step_comment.comment_id = 2343434
    assert_not @step_comment.valid?
    @step_comment.comment = nil
    assert_not @step_comment.valid?
  end

  test "should not validate with non existent step id" do
    @step_comment.step_id = 1223232323
    assert_not @step_comment.valid?
    @step_comment.step = nil
    assert_not @step_comment.valid?
  end

  test "should have association steps -> comment" do
    assert_empty @step.comments
    @step.comments << @comment
    assert_equal @comment, Step.find(@step.id).comments.first, "There is no association between step -> comment."
  end
end
