# frozen_string_literal: true

class TeamRepository < ApplicationRecord
<<<<<<< HEAD
  enum permission_level: Extends::SHARED_INVENTORIES_PERMISSION_LEVELS.except(:not_shared)
=======
  enum permission_level: Extends::SHARED_INVENTORIES_PERMISSION_LEVELS
>>>>>>> Finished merging. Test on dev machine (iMac).

  belongs_to :team
  belongs_to :repository

<<<<<<< HEAD
  before_destroy :unassign_unshared_items

=======
>>>>>>> Finished merging. Test on dev machine (iMac).
  validates :permission_level, presence: true
  validates :repository, uniqueness: { scope: :team_id }
  validate :team_cannot_be_the_same

  private

  def team_cannot_be_the_same
    errors.add(:team_id, :same_team) if repository&.team_id == team_id
  end
<<<<<<< HEAD

  def unassign_unshared_items
    return if repository.shared_read? || repository.shared_write?

    MyModuleRepositoryRow.joins(my_module: { experiment: { project: :team } })
                         .joins(repository_row: :repository)
                         .where(my_module: { experiment: { projects: { team: team } } })
                         .where(repository_rows: { repository: repository })
                         .destroy_all
  end
=======
>>>>>>> Finished merging. Test on dev machine (iMac).
end
