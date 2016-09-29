class Checklist < ActiveRecord::Base
  include SearchableModel

  auto_strip_attributes :name, nullify: false
  validates :name, presence: true, length: { maximum: TEXT_MAX_LENGTH }
  validates :step, presence: true

  belongs_to :step, inverse_of: :checklists
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User'
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
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

  def self.search(user, include_archived, query = nil, page = 1)
    step_ids =
      Step
      .search(user, include_archived, nil, SEARCH_NO_LIMIT)
      .select("id")

    if query
      a_query = query.strip
      .gsub("_","\\_")
      .gsub("%","\\%")
      .split(/\s+/)
      .map {|t|  "%" + t + "%" }
    else
      a_query = query
    end

    new_query = Checklist
        .distinct
        .where("checklists.step_id IN (?)", step_ids)
        .joins("LEFT JOIN checklist_items ON checklists.id = checklist_items.checklist_id")
        .where_attributes_like(["checklists.name",  "checklist_items.text"], a_query)

    # Show all results if needed
    if page == SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(SEARCH_LIMIT)
        .offset((page - 1) * SEARCH_LIMIT)
    end
  end

end
