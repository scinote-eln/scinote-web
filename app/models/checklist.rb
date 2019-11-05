class Checklist < ApplicationRecord
  include SearchableModel

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

  accepts_nested_attributes_for :checklist_items,
    reject_if: :all_blank,
    allow_destroy: true

  scope :asc, -> { order('checklists.created_at ASC') }

  def self.search(user,
                  include_archived,
                  query = nil,
                  page = 1,
                  _current_team = nil,
                  options = {})
    step_ids =
      Step
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)

    new_query =
      Checklist
      .distinct
      .where('checklists.step_id IN (?)', step_ids)
      .joins('LEFT JOIN checklist_items ON ' \
             'checklists.id = checklist_items.checklist_id')
      .where_attributes_like(['checklists.name', 'checklist_items.text'],
                             query, options)

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end
end
