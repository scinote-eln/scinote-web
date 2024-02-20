class ChecklistItem < ApplicationRecord

  attr_accessor :with_paragraphs

  auto_strip_attributes :text, nullify: false
  validates :text,
            presence: true,
            length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :checklist, presence: true
  validates :checked, inclusion: { in: [true, false] }
  validates :position, uniqueness: { scope: :checklist }

  belongs_to :checklist,
             inverse_of: :checklist_items
  acts_as_list scope: :checklist, top_of_list: 0, sequential_updates: true
  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true

  # conditional touch excluding checked updates
  after_destroy :touch_checklist
  after_save :touch_checklist
  after_touch :touch_checklist

  def save_multiline!(after_id: nil)
    at_position = checklist.checklist_items.find_by(id: after_id).position if after_id

    if with_paragraphs
      if new_record?
        save!
        insert_at(at_position + 1) || 0
      else
        save!
      end
      return [self]
    end

    items = []
    if new_record?
      start_position = at_position || 0
      text.split("\n").compact.each do |line|
        new_item = checklist.checklist_items.create!(text: line)
        new_item.insert_at(start_position + 1)
        start_position = new_item.position
        items.push(new_item)
      end
    else
      item = self
      text.split("\n").compact.each_with_index do |line, index|
        if index.zero?
          update!(text: line)
          items.push(self)
        else
          new_item = checklist.checklist_items.create!(text: line)
          new_item.insert_at(item.position + 1)
          item = new_item
          items.push(new_item)
        end
      end
    end
    items
  end

  private

  def touch_checklist
    # if only checklist item checked attribute changed, do not touch checklist
    return if saved_changes.keys.sort == %w(checked updated_at)

    # rubocop:disable Rails/SkipsModelValidations
    checklist.touch
    # rubocop:enable Rails/SkipsModelValidations
  end
end
