class Tag < ActiveRecord::Base
  include SearchableModel

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :color, presence: true, length: { maximum: COLOR_MAX_LENGTH }
  validates :project, presence: true

  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User'
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  belongs_to :project
  has_many :my_module_tags, inverse_of: :tag, :dependent => :destroy
  has_many :my_modules, through: :my_module_tags

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

    new_query = Tag
      .distinct
      .where("tags.project_id IN (?)", project_ids)
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

  def deep_clone_to_project(project)
    Tag.create(
      name: name,
      color: color,
      created_by: created_by,
      last_modified_by: last_modified_by,
      project: project
    )
  end
end
