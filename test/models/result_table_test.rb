require 'test_helper'

class ResultTableTest < ActiveSupport::TestCase
  def setup
    @result_table = result_tables(:test)
  end

  test "should validate with correct data" do
    assert @result_table.valid?
  end

  test "should not validate with non existent result_id" do
    @result_table.result_id = 123123
    assert_not @result_table.valid?
    @result_table.result = nil
    assert_not @result_table.valid?
  end

  test "should not validate with non existent table_id" do
    @result_table.table_id = 12321321
    assert_not @result_table.valid?
    @result_table.table = nil
    assert_not @result_table.valid?
  end

  test "should have association result -> table" do
    result = Result.new(
      name: "Result test",
      user: users(:steve),
      my_module: my_modules(:list_of_samples))
    table = tables(:test)

    assert_nil result.asset
    assert_nil result.table
    assert_nil result.result_text

    result.table = table
    result.save
    assert_equal table, Result.find(result.id).table
  end

  test "should destroy dependent tables" do
    result_table = result_tables(:one)
    assert Table.find(result_table.table_id)
    assert result_table.destroy
    assert_not Table.find_by_id(result_table.table_id)
  end
end
