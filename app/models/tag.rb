# frozen_string_literal: true

class Tag < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :name, :color, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :color,
            presence: true,
            length: { maximum: Constants::COLOR_MAX_LENGTH }
  validates :project, presence: true

  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true
  belongs_to :project
  has_many :my_module_tags, inverse_of: :tag, dependent: :destroy
  has_many :my_modules, through: :my_module_tags

  def self.search(user,
                  include_archived,
                  query = nil,
                  page = 1,
                  _current_team = nil,
                  options = {})
    project_ids =
      Project
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)

    new_query = Tag
                .distinct
                .where('tags.project_id IN (?)', project_ids)
                .where_attributes_like(:name, query, options)

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def clone_to_project_or_return_existing(project)
    tag = Tag.find_by(project: project, name: name, color: color)
    return tag if tag

    Tag.create(
      name: name,
      color: color,
      created_by: created_by,
      last_modified_by: last_modified_by,
      project: project
    )
  end
end
