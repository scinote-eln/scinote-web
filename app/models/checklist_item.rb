class ChecklistItem < ActiveRecord::Base
  validates :text,
    presence: true,
    length: { maximum: 1000 }
  validates :checklist, presence: true
  validates :checked, inclusion: { in: [true, false] }

  belongs_to :checklist, inverse_of: :checklist_items
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User'
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
end
