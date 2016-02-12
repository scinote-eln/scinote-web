require 'test_helper'

class ChecklistTest < ActiveSupport::TestCase
  test "should validate with correct data" do
    checklist = Checklist.new(
      name: "test",
      step: steps(:step1)
    )
    assert checklist
  end

  test "should not validate without name" do
    checklist = Checklist.new(step: steps(:step1))
    assert_not checklist.valid?
  end

  test "should not validate with name too long" do
    checklist = Checklist.new(
      name: "#" * 51,
      step: steps(:step1)
    )
    assert_not checklist.valid?
  end

  test "should not validate with non existent step" do
    checklist = Checklist.new(
      name: "test",
      step_id: 123123)
    assert_not checklist.valid?
  end

  test "should have association step -> checklist" do
    checklist = Checklist.new(
      name: "test",
      step: steps(:step1))
    step = Step.create(name: "Step test", position: 0, completed: 0, user: users(:steve), my_module: my_modules(:sample_prep))

    assert_empty step.checklists
    step.checklists << checklist

    assert_equal checklist, Step.find(step.id).checklists.first
  end

end
