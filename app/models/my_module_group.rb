class MyModuleGroup < ActiveRecord::Base
  include SearchableModel

  validates :name,
    presence: true,
    length: { maximum: 50 }
  validates :experiment, presence: true

  belongs_to :experiment, inverse_of: :my_module_groups
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User'
  has_many :my_modules, inverse_of: :my_module_group,
    dependent: :nullify

  def self.search(user, include_archived, query = nil, page = 1)
    project_ids =
      Project
      .search(user, include_archived, nil, SHOW_ALL_RESULTS)
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

    new_query = MyModuleGroup
      .distinct
      .where("my_module_groups.project_id IN (?)", project_ids)
      .where_attributes_like(:name, a_query)

    # Show all results if needed
    if page == SHOW_ALL_RESULTS
      new_query
    else
      new_query
        .limit(SEARCH_LIMIT)
        .offset((page - 1) * SEARCH_LIMIT)
    end
  end

  def ordered_modules
    my_modules.order(workflow_order: :asc)
  end
end
