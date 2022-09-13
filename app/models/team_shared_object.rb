# frozen_string_literal: true

class TeamSharedObject < ApplicationRecord
  enum permission_level: Extends::SHARED_OBJECTS_PERMISSION_LEVELS

  belongs_to :team
  belongs_to :shared_object, polymorphic: true
  belongs_to :shared_repository,
             (lambda do |team_shared_object|
               team_shared_object.shared_object_type == 'RepositoryBAse' ? self : none
             end),
             optional: true, foreign_key: :shared_object_id, inverse_of: :team_shared_object

  before_destroy :unassign_unshared_items, if: -> { shared_object.is_a?(Repository) }

  validates :permission_level, presence: true
  validates :shared_object, uniqueness: { scope: :team_id }
  validate :team_cannot_be_the_same

  private

  def team_cannot_be_the_same
    errors.add(:team_id, :same_team) if shared_object.team.id == team_id
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
