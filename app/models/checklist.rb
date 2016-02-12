class Checklist < ActiveRecord::Base
  validates :name,
    presence: true,
    length: { maximum: 50 }
  validates :step, presence: true

  belongs_to :step, inverse_of: :checklists
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User'
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  has_many :checklist_items,
    inverse_of: :checklist,
    dependent: :destroy
  has_many :report_elements,
    inverse_of: :checklist,
    dependent: :destroy

  accepts_nested_attributes_for :checklist_items,
    reject_if: :all_blank,
    allow_destroy: true

  # TODO: get the current_user
  # before_save do
  #   if current_user
  #     self.created_by ||= current_user
  #     self.last_modified_by = current_user if self.changed?
  #   end
  # end
end
