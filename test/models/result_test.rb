require 'test_helper'
require 'helpers/archivable_model_test_helper'
require 'helpers/searchable_model_test_helper'

class ResultTest < ActiveSupport::TestCase
  include ArchivableModelTestHelper
  include SearchableModelTestHelper

  def setup
    @result = results(:test_result)
  end

  test "should be valid with correct data" do
    assert @result.valid?, @result.errors.messages
  end

  test "should validate with blank text" do
    @result.name = ""
    assert @result.valid?
    @result.name = " "
    assert @result.valid?
    @result.name = nil
    assert @result.valid?
  end

  test "should validate name length" do
    @result.name *= 50
    assert_not @result.valid?
  end

  test "should not validate with non existent user" do
    @result.user_id = 12321321
    assert_not @result.valid?
    @result.user = nil
    assert_not @result.valid?
  end

  test "should not validate with non existent my_module" do
    @result.my_module_id = 1231232
    assert_not @result.valid?
    @result.my_module = nil
    assert_not @result.valid?
  end

  test "should not validate with having no text, asset nor table" do
    result = Result.new(
      user: users(:steve),
      my_module: my_modules(:sample_prep))
    assert_not result.valid?, "Result should not be valid without text, asset nor table set."
  end

  test "should not validate with being text, asset, table at the same time" do
    result = results(:no_items)
    result.result_text = result_texts(:one)
    assert result.valid?, "Result should be valid with only result_text."

    result.asset = assets(:one)
    assert_not result.valid? "Result should not be valid with both result_text and asset."

    result.table = Table.new(contents: "test")
    assert_not result.valid?, "Result should not be valid with all types assigned."
  end

  test "should validate with only asset present" do
    result = results(:no_items)
    result.asset = assets(:one)
    assert result.valid?
  end

  test "should have archived set" do
    result = results(:no_items)
    result.asset = assets(:one)
    assert_archived_present(result)
    assert_active_is_inverse_of_archived(result)
  end

  test "archiving should work" do
    result = results(:no_items)
    result.asset = assets(:one)
    result.save
    archive_and_restore_action_test(result, result.user)
  end

  test "where_attributes_like should work" do
    attributes_like_test(Result, :name, "text nr. 1")
  end

  test "should test for asset type of result" do
    result = results(:no_items)
    assert_not result.is_asset
    result.asset = assets(:one)
    assert result.is_asset
  end

  test "should test for table type of result" do
    result = results(:no_items)
    assert_not result.is_table
    result.table = tables(:test)
    assert result.is_table
  end

  test "should test for text type of result" do
    result = results(:no_items)
    assert_not result.is_text
    result.result_text = result_texts(:one)
    assert result.is_text
  end

  test "should get last comments" do
    last_comments = results(:test2).last_comments
    first_comment = comments(:test_result_comment_24)
    last_comment = comments(:test_result_comment_5)
    assert_equal 20, last_comments.size
    assert_equal first_comment, last_comments.last
    assert_equal last_comment, last_comments.first
  end

  # Not possible to test with fixtures and random id values
  test "should get last comments before specific comment" do
    skip
  end

  test "should get last comments of specified length" do
    last_comments = results(:test2).last_comments(0, 5)
    first_comment = comments(:test_result_comment_24)
    last_comment = comments(:test_result_comment_20)
    assert_equal 5, last_comments.size
    assert_equal first_comment, last_comments.last
    assert_equal last_comment, last_comments.first
  end

  test "should search for results of user" do
    skip('pending............ must implement search in Experiment model first')
    search_results = Result.search(users(:steve), false)
    assert_equal 7, search_results.size
  end

  test "should search archived results of user" do
    skip('pending............ must implement search in Experiment model first')
    search_results = Result.search(users(:steve), true)
    assert_equal 8, search_results.size
  end

  test "should search results by name" do
    skip('pending............ must implement search in Experiment model first')
    search_results = Result.search(users(:steve), false, "table")
    assert_equal 1, search_results.size
  end

  test "should search archived results by name" do
    skip('pending............ must implement search in Experiment model first')
    search_results = Result.search(users(:steve), true, "table")
    assert_equal 2, search_results.size
  end

  test "should have association result -> comment" do
    num_of_comments = @result.comments.size
    comment = comments(:one)
    @result.comments << comment
    assert_equal comment, Result.find(@result.id).comments.last, "There is no association between result -> comment."
    assert_equal num_of_comments + 1, @result.comments.size
  end
end
