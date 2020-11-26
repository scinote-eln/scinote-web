# frozen_string_literal: true

class ProjectFolder < ApplicationRecord
  include SearchableModel
  include SearchableByNameModel

  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :team_id, case_sensitive: false }

  before_validation :inherit_team_from_parent_folder, if: -> { team.blank? && parent_folder.present? }

  belongs_to :team, inverse_of: :project_folders, touch: true
  belongs_to :parent_folder, class_name: 'ProjectFolder', optional: true
  has_many :projects, inverse_of: :project_folder, dependent: :nullify
  has_many :project_folders, foreign_key: 'parent_folder_id', inverse_of: :parent_folder, dependent: :destroy

  scope :top_level, -> { where(parent_folder: nil) }

  def self.search(user, _include_archived, query = nil, page = 1, current_team = nil, options = {})
    new_query = if current_team
                  current_team.project_folders.where_attributes_like(:name, query, options)
                else
                  distinct.joins(team: :user_teams)
                          .where(teams: { user_teams: { user: user } })
                          .where_attributes_like('project_folders.name', query, options)
                end

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query.limit(Constants::SEARCH_LIMIT).offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def self.inner_folders(team, project_folder = nil)
    entry_point_condition = project_folder ? 'parent_folder_id = ?' : 'parent_folder_id IS NULL'
    inner_folders_sql =
      "WITH RECURSIVE inner_project_folders(id, selected_folders_ids) AS (
        SELECT id, ARRAY[id]
        FROM project_folders
        WHERE team_id = ? AND #{entry_point_condition}
        UNION ALL
        SELECT project_folders.id, selected_folders_ids || project_folders.id
        FROM inner_project_folders
        JOIN project_folders ON project_folders.parent_folder_id = inner_project_folders.id
        WHERE NOT project_folders.id = ANY(selected_folders_ids)
      )
      SELECT id FROM inner_project_folders ORDER BY selected_folders_ids".gsub(/\n|\t/, ' ').gsub(/ +/, ' ')

    new_query =
      if project_folder.present?
        where("project_folders.id IN (#{inner_folders_sql})", team.id, project_folder.id)
      else
        where("project_folders.id IN (#{inner_folders_sql})", team.id)
      end
    new_query.order(:parent_folder_id)
  end

  def inner_projects
    project_folders.map do |inner_folder|
      projects + inner_folder.inner_projects
    end.flatten
  end

  private

  def inherit_team_from_parent_folder
    self.team = parent_folder.team
  end
end
