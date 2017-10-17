require 'test_helper'
require 'helpers/searchable_model_test_helper'

class TagTest < ActiveSupport::TestCase
  include SearchableModelTestHelper

  def setup
    @tag = tags(:urgent)
    @user = users(:steve)
  end

  test "should not validate without name" do
    assert @tag.valid?
    @tag.name = nil
    assert_not @tag.valid?
  end

  test "should not have name too long" do
    assert @tag.valid?
    @tag.name *= 50
    assert_not @tag.valid?
  end

  test "should not validate without color" do
    assert @tag.valid?
    @tag.color = nil
    assert_not @tag.valid?
  end

  test "should not validate without project" do
    assert @tag.valid?
    @tag.project_id = 0
    assert_not @tag.valid?
    @tag.project = nil
    assert_not @tag.valid?
  end

  test "where_attributes_like should work" do
    attributes_like_test(Tag, :name, "to")
  end

  test "should get user's tags" do
    tags = Tag.search(@user, false)
    assert_equal 4, tags.size
  end

  test "should get user's tags including archived" do
    tags = Tag.search(@user, true)
    assert_equal 5, tags.size
  end

  test "should search user's tags by name" do
    tags = Tag.search(@user, false, "do")
    assert_equal 1, tags.size
  end

  test "should search user's tags by color" do
    tags = Tag.search(@user, false, "classified")
    assert_equal 1, tags.size
  end

  test "should search user's tags by color including archived" do
    tags = Tag.search(@user, true, "old")
    assert_equal 1, tags.size
  end
end
