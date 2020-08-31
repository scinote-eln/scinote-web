# frozen_string_literal: true

class TeamRepository < ApplicationRecord
  enum permission_level: Extends::SHARED_INVENTORIES_PERMISSION_LEVELS.except(:not_shared)

  belongs_to :team
  belongs_to :repository

  before_destroy :unassign_unshared_items

  validates :permission_level, presence: true
  validates :repository, uniqueness: { scope: :team_id }
  validate :team_cannot_be_the_same

  private

  def team_cannot_be_the_same
    errors.add(:team_id, :same_team) if repository&.team_id == team_id
  end

  def unassign_unshared_items
    return if repository.shared_read? || repository.shared_write?

    MyModuleRepositoryRow.joins(my_module: { experiment: { project: :team } })
                         .joins(repository_row: :repository)
                         .where(my_module: { experiment: { projects: { team: team } } })
                         .where(repository_rows: { repository: repository })
                         .destroy_all
  end
end
