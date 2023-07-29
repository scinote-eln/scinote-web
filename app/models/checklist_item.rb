class ChecklistItem < ApplicationRecord
  auto_strip_attributes :text, nullify: false
  validates :text,
            presence: true,
            length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :checklist, presence: true
  validates :checked, inclusion: { in: [true, false] }
  validates :position, uniqueness: { scope: :checklist }

  belongs_to :checklist,
             inverse_of: :checklist_items
  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true

  after_destroy :update_positions

  # conditional touch excluding checked updates
  after_destroy :touch_checklist
  after_save :touch_checklist
  after_touch :touch_checklist

  private

  def touch_checklist
    # if only checklist item checked attribute changed, do not touch checklist
    return if saved_changes.keys.sort == %w(checked updated_at)

    # rubocop:disable Rails/SkipsModelValidations
    checklist.touch
    # rubocop:enable Rails/SkipsModelValidations
  end

  def update_positions
    transaction do
      checklist.checklist_items.order(position: :asc).each_with_index do |checklist_item, i|
        checklist_item.update!(position: i)
      end
    end
  end
end
