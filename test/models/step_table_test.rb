require 'test_helper'

class StepTableTest < ActiveSupport::TestCase
  def setup
    @user = users(:jlaw)
    @step = steps(:test)
    @step_table = step_tables(:test)
    @table = tables(:test)
  end

  test "should validate with correct data" do
    assert @step_table.valid?
  end

  test "should not validate with non existent step_id" do
    @step_table.step_id = 123123
    assert_not @step_table.valid?
  end

  test "should not validate with non existent table_id" do
    @step_table.table_id = 12321321
    assert_not @step_table.valid?
  end

  test "should have association step -> table" do
    step = steps(:empty)
    assert_empty step.tables

    step.tables << @table
    assert_equal @table, Step.find(step.id).tables.first
  end
end
