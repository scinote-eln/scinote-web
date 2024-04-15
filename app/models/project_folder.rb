# frozen_string_literal: true

class ProjectFolder < ApplicationRecord
  ID_PREFIX = 'PF'
  include PrefixedIdModel

  include ArchivableModel
  include SearchableModel
  include SearchableByNameModel

  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: %i(team_id parent_folder_id archived), case_sensitive: false }
  validate :parent_folder_team, if: -> { parent_folder.present? }
  validate :parent_folder_validation, if: -> { parent_folder.present? }

  before_validation :inherit_team_from_parent_folder, on: :create, if: -> { parent_folder.present? }
  before_validation :ensure_uniqueness_name_on_moving, on: :update, if: -> { parent_folder_id_changed? }

  belongs_to :team, inverse_of: :project_folders, touch: true
  belongs_to :parent_folder, class_name: 'ProjectFolder', optional: true, touch: true
  belongs_to :archived_by, foreign_key: 'archived_by_id',
                           class_name: 'User',
                           inverse_of: :archived_project_folders,
                           optional: true
  belongs_to :restored_by, foreign_key: 'restored_by_id',
                           class_name: 'User',
                           inverse_of: :restored_project_folders,
                           optional: true
  has_many :projects, inverse_of: :project_folder, dependent: :nullify
  has_many :project_folders, foreign_key: 'parent_folder_id', inverse_of: :parent_folder, dependent: :destroy

  scope :top_level, -> { where(parent_folder: nil) }

  def self.search(user, _include_archived, query = nil, page = 1, current_team = nil, options = {})
    new_query = if current_team
                  current_team.project_folders.where_attributes_like(:name, query, options)
                else
                  distinct.joins(team: :users)
                          .where(teams: { user_assignments: { user: user } })
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

    if project_folder.present?
      where("project_folders.id IN (#{inner_folders_sql})", team.id, project_folder.id)
    else
      where("project_folders.id IN (#{inner_folders_sql})", team.id)
    end
  end

  def self.filter_by_teams(teams = [])
    teams.blank? ? self : where(team: teams)
  end

  def parent_folders
    outer_folders_sql =
      'WITH RECURSIVE outer_project_folders(id, parent_folder_id, selected_folders_ids) AS (
        SELECT id, parent_folder_id, ARRAY[id]
        FROM project_folders
        WHERE team_id = ? AND id = ?
        UNION ALL
        SELECT project_folders.id, project_folders.parent_folder_id, selected_folders_ids || project_folders.id
        FROM outer_project_folders
        JOIN project_folders ON project_folders.id = outer_project_folders.parent_folder_id
        WHERE NOT project_folders.id = ANY(selected_folders_ids)
      )
      SELECT id FROM outer_project_folders ORDER BY selected_folders_ids'.gsub(/\n|\t/, ' ').gsub(/ +/, ' ')

    ProjectFolder.where("project_folders.id IN (#{outer_folders_sql})", team.id, id)
  end

  def inner_projects
    Project.where(project_folder: ProjectFolder.inner_folders(team, self) + [self])
  end

  def archived_branch?
    return false if active? && parent_folder.blank?
    return true if archived?

    parent_folder.present? && parent_folder.archived_branch?
  end

  private

  def inherit_team_from_parent_folder
    self.team = parent_folder.team
  end

  def parent_folder_team
    return if parent_folder.team_id == team_id

    errors.add(:parent_folder, I18n.t('activerecord.errors.models.project_folder.attributes.parent_folder_team'))
  end

  def parent_folder_validation
    if parent_folder.id == id
      errors.add(:parent_folder, I18n.t('activerecord.errors.models.project_folder.attributes.parent_folder'))
    elsif ProjectFolder.inner_folders(team, self).where(id: parent_folder_id).exists?
      errors.add(:parent_folder, I18n.t('activerecord.errors.models.project_folder.attributes.parent_folder_child'))
    end
  end

  def ensure_uniqueness_name_on_moving
    return unless self.class.where(parent_folder: parent_folder).where('name ILIKE ?', name).any?

    regex = /\((\d+)\)/
    max_number = self.class
                     .where(parent_folder: parent_folder)
                     .where('name ILIKE ?', "#{name} (%)")
                     .order(name: :desc)
                     .pluck(:name)
                     .select { |s| s.match(regex) }
                     .map { |s| s.match(regex)[1].to_i }
                     .max || 0

    self.name = name + " (#{max_number + 1})"
  end
end
