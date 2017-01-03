require 'test_helper'

class ChecklistTest < ActiveSupport::TestCase
  should validate_presence_of(:step)
  should validate_presence_of(:name)
  should validate_length_of(:name).is_at_most(Constants::TEXT_MAX_LENGTH)

  test "should validate with correct data" do
    checklist = Checklist.new(
      name: "test",
      step: steps(:step1)
    )
    assert checklist
  end

  test "should have association step -> checklist" do
    checklist = Checklist.new(
      name: "test",
      step: steps(:step1))
    step = Step.create(name: "Step test", position: 0, completed: 0, user: users(:steve), protocol: protocols(:rna_test_protocol))

    assert_empty step.checklists
    step.checklists << checklist

    assert_equal checklist, Step.find(step.id).checklists.first
  end

end
