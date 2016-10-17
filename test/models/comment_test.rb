require 'test_helper'

class CommentTest < ActiveSupport::TestCase

  def setup
    @valid = Comment.new(
      message: "test",
      user: users(:steve),
    )
    ResultComment.new(
      result: results(:one),
      comment: @valid
    )
  end

  should validate_presence_of(:message)
  should validate_length_of(:message).is_at_most(Constants::TEXT_MAX_LENGTH)

  test "should validate" do
    assert @valid.valid?
  end

  test "should not validate with empty user_id" do
    comment = Comment.new(message: "Message")
    assert_not comment.valid?, "Comment was created with empty user_id."
  end

  test "should not validate with non existent user" do
    comment  = Comment.new(message: "comment", user_id: 123123)
    assert_not comment.valid?, "Comment was created with user who doesn't exist."
  end

  test "should not validate with more than one assigned object" do
    StepComment.new(
      step: steps(:step1),
      comment: @valid
    )
    ResultComment.new(
      result: results(:one),
      comment: @valid
    )
    assert_not @valid.valid?, "Comment was valid with more than one assigned object."
  end

  test "should not validate with no assigned object" do
    skip # Omit due to GUI problems (see comment.rb)
    @valid.step_comment = nil
    @valid.my_module_comment = nil
    @valid.result_comment = nil
    @valid.sample_comment = nil
    @valid.project_comment = nil
    assert_not @valid.valid?, "Comment was valid despite having no assigned object."
  end

  test "should have association comment -> user" do
    user = users(:jlaw)
    comment = Comment.create(message: "comment", user: user)
    assert_equal user, Comment.find(comment.id).user
  end
end
