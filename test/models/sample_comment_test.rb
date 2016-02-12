require 'test_helper'

class SampleCommentTest < ActiveSupport::TestCase
  def setup
    @sample_comment = sample_comments(:one)
    @user = users(:nora)
    @sample = samples(:sample1)
  end

  test "should validate with correct data" do
    assert @sample_comment.valid?
  end

  test "should not validate with non existent comment id" do
    @sample_comment.comment_id = 2343434
    assert_not @sample_comment.valid?
    @sample_comment.comment = nil
    assert_not @sample_comment.valid?
  end

  test "should not validate with non existent sample id" do
    @sample_comment.sample_id = 1223232323
    assert_not @sample_comment.valid?
    @sample_comment.sample = nil
    assert_not @sample_comment.valid?
  end

  test "should allow only unique associations" do
    sample_comment = SampleComment.new
    sample_comment.sample = @sample_comment.sample
    sample_comment.comment = @sample_comment.comment
    assert_not sample_comment.save
  end

  test "should have association sample -> comment" do
    comment = comments(:unassociated)
    @sample.comments << comment
    assert_equal comment, Sample.find(@sample.id).comments.last, "There is no association between sample -> comment."
  end
end
