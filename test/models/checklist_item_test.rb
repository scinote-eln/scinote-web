require 'test_helper'

class ChecklistItemTest < ActiveSupport::TestCase
  should validate_presence_of(:text)
  should validate_length_of(:text)
    .is_at_most(Constants::TEXT_MAX_LENGTH)

  test "should validate with correct data" do
    chkItem = ChecklistItem.new(
      text: "test",
      checked: false,
      checklist: checklists(:one)
    )
    assert chkItem.valid?
  end

  test "should not validate without checked value" do
    chkItem = ChecklistItem.new(
      text: "text", checked: nil,
      checklist: checklists(:one))
    assert_not chkItem.valid?, "Checklist item was created without checked value."
  end

  test "should not validate with non existent checklist" do
    chkItem = ChecklistItem.new(
      text: "text", checked: false,
      checklist_id: 1231234121)
    assert_not chkItem.valid?, "Checklist item was created with checklist which doesn't exist."
  end

  test "should have association checklist <-> checklist item" do
    checklist = Checklist.create(
      name: "Checklist 17",
      step: steps(:step1))
    item = ChecklistItem.create(
      text: "text", checked: false,
      checklist: checklist)

    checklist.checklist_items << item
    assert_equal item, Checklist.find(checklist.id).checklist_items.first, "No association checklist -> checklist item."
    assert_equal checklist, ChecklistItem.find(item.id).checklist, "No association checklist item -> checklist."
  end
end
