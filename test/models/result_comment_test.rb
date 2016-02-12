require 'test_helper'

class ResultCommentTest < ActiveSupport::TestCase
  def setup
    @result_comment = result_comments(:test)
  end

  test "should validate with correct data" do
    assert @result_comment.valid?
  end

  test "should not validate with non existent comment id" do
    @result_comment.comment_id = 2343434
    assert_not @result_comment.valid?
    @result_comment.comment = nil
    assert_not @result_comment.valid?
  end

  test "should not validate with non existent result id" do
    @result_comment.result_id = 1223232323
    assert_not @result_comment.valid?
    @result_comment.result = nil
    assert_not @result_comment.valid?
  end

  test "should validate uniqueness" do
    result_comment = ResultComment.new(
      result: @result_comment.result, comment: @result_comment.comment)
    assert_not result_comment.save
  end

  test "should destroy dependent comments" do
    result_comment = result_comments(:one)
    assert Comment.find(result_comment.comment_id)
    assert result_comment.destroy
    assert_not Comment.find_by_id(result_comment.comment_id)
  end
end
