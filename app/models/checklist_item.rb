class ChecklistItem < ApplicationRecord
  auto_strip_attributes :text, nullify: false
  validates :text,
            presence: true,
            length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :checklist, presence: true
  validates :checked, inclusion: { in: [true, false] }
  validates :position, uniqueness: { scope: :checklist }, unless: -> { position.nil? }

  belongs_to :checklist,
             inverse_of: :checklist_items,
             touch: true
  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true

  after_destroy :update_positions

  private

  def update_positions
    transaction do
      checklist.checklist_items.order(position: :asc).each_with_index do |checklist_item, i|
        checklist_item.update!(position: i)
      end
    end
  end
end
