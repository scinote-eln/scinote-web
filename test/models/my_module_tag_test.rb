require 'test_helper'

class MyModuleTagTest < ActiveSupport::TestCase
  def setup
    @my_module = my_modules(:qpcr)
    @tag = tags(:todo)
    @module_tag = MyModuleTag.new(
      my_module: @my_module, tag: @tag)
    assert @module_tag.save
  end

  test "should validate with correct data" do
    assert @module_tag.valid?
  end

  test "should not validate with non existent tag id" do
    @module_tag.tag_id = 2343434
    assert_not @module_tag.valid?
    @module_tag.tag = nil
    assert_not @module_tag.valid?
  end

  test "should not validate with non existent module id" do
    @module_tag.my_module_id = 1223232323
    assert_not @module_tag.valid?
    @module_tag.my_module = nil
    assert_not @module_tag.valid?
  end

  test "should check module/tag uniqueness" do
    module_tag = MyModuleTag.new(
      my_module: @my_module, tag: @tag)
    assert_not module_tag.save
  end

  test "should have association my_module -> tag" do
    tag = tags(:urgent)
    @my_module.tags << tag
    assert_equal tag, MyModule.find(@my_module.id).tags.last,
      "There is no association between my_module -> tag."
  end
end
