# frozen_string_literal: true

class ProjectFolder < ApplicationRecord
  include SearchableModel
  include SearchableByNameModel

  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :team_id, case_sensitive: false }

  before_validation :inherit_team_from_parent_folder, if: -> { parent_folder.present? }

  belongs_to :team, inverse_of: :project_folders, touch: true
  belongs_to :parent_folder, class_name: 'ProjectFolder', optional: true
  has_many :projects, inverse_of: :project_folder, dependent: :nullify
  has_many :project_folders, foreign_key: 'parent_folder_id', inverse_of: :parent_folder, dependent: :destroy

  scope :top_level, -> { where(parent_folder: nil) }

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
