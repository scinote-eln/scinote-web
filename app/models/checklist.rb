class Checklist < ApplicationRecord
  include SearchableModel
  include ObservableModel

  SEARCHABLE_ATTRIBUTES = ['checklists.name'].freeze

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :step, presence: true

  belongs_to :step, inverse_of: :checklists, touch: true
  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  has_many :checklist_items,
    -> { order(:position) },
    inverse_of: :checklist,
    dependent: :destroy
  has_many :report_elements,
    inverse_of: :checklist,
    dependent: :destroy
  has_one :step_orderable_element, as: :orderable, dependent: :destroy

  accepts_nested_attributes_for :checklist_items,
    reject_if: :all_blank,
    allow_destroy: true

  scope :asc, -> { order('checklists.created_at ASC') }

  def duplicate(step, user, position = nil)
    ActiveRecord::Base.transaction do
      new_checklist = step.checklists.create!(
        name: name,
        created_by: user,
        last_modified_by: user
      )

      checklist_items.each do |item|
        new_checklist.checklist_items.create!(
          text: item.text,
          checked: false,
          position: item.position,
          created_by: user,
          last_modified_by: user
        )
      end

      step.step_orderable_elements.create!(
        position: position || step.step_orderable_elements.length,
        orderable: new_checklist
      )

      new_checklist
    end
  end
end
