require 'test_helper'

class MyModuleCommentTest < ActiveSupport::TestCase
  def setup
    @module_comment = my_module_comments(:test) 
    @my_module = @module_comment.my_module
    @comment = @module_comment.comment
  end

  test "should validate with correct data" do
    assert @module_comment.valid?
  end

  test "should not validate with non existent comment id" do
    @module_comment.comment_id = 2343434
    assert_not @module_comment.valid?
    @module_comment.comment = nil
    assert_not @module_comment.valid?
  end

  test "should not validate with non existent module id" do
    @module_comment.my_module_id = 1223232323
    assert_not @module_comment.valid?
    @module_comment.my_module = nil
    assert_not @module_comment.valid?
  end

  test "should check module/comment uniqueness" do
    module_comment = MyModuleComment.new(
      my_module: @my_module, comment: @comment)
    assert_not module_comment.save
  end

  test "should have association my_module -> comment" do
    @my_module.comments << comments(:unassociated)
    assert_equal @comment, MyModule.find(@my_module.id).comments.first,
      "There is no association between my_module -> comment."
  end
end
