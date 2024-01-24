# frozen_string_literal: true

class TeamSharedObject < ApplicationRecord
  enum permission_level: Extends::SHARED_OBJECTS_PERMISSION_LEVELS.except(:not_shared)

  after_create :assign_shared_inventories, if: -> { shared_object.is_a?(Repository) }
  before_destroy :unlink_unshared_items, if: -> { shared_object.is_a?(Repository) }
  before_destroy :unassign_unshared_items, if: -> { shared_object.is_a?(Repository) }
  before_destroy :unassign_unshared_inventories, if: -> { shared_object.is_a?(Repository) }

  belongs_to :team
  belongs_to :shared_object, polymorphic: true, inverse_of: :team_shared_objects
  belongs_to :shared_repository,
             (lambda do |team_shared_object|
               team_shared_object.shared_object_type == 'RepositoryBase' ? self : none
             end),
             optional: true,
             class_name: 'RepositoryBase',
             foreign_key: :shared_object_id

  validates :permission_level, presence: true
  validates :shared_object_type, uniqueness: { scope: %i(shared_object_id team_id) }
  validate :team_cannot_be_the_same
  validate :not_globally_shared, if: -> { shared_object.is_a?(Repository) }

  private

  def team_cannot_be_the_same
    errors.add(:team_id, :same_team) if shared_object.team.id == team_id
  end

  def not_globally_shared
    errors.add(:shared_object_id, :is_globally_shared) if shared_object.globally_shared?
  end

  def assign_shared_inventories
    team.user_assignments.find_each do |user_assignment|
      shared_object.user_assignments.create!(
        user: user_assignment.user,
        user_role: user_assignment.user_role,
        team: team
      )
    end
  end

  def unassign_unshared_items
    return if shared_object.shared_read? || shared_object.shared_write?

    MyModuleRepositoryRow.joins(my_module: { experiment: { project: :team } })
                         .joins(repository_row: :repository)
                         .where(my_module: { experiment: { projects: { team: team } } })
                         .where(repository_rows: { repository: shared_object })
                         .destroy_all
  end

  def unassign_unshared_inventories
    team.repository_sharing_user_assignments.where(assignable: shared_object).find_each(&:destroy!)
  end

  def unlink_unshared_items
    # We keep all the other teams shared with and the repository's own team
    teams_ids = shared_object.teams_shared_with.where.not(id: team).pluck(:id)
    teams_ids << shared_object.team_id
    repository_rows_ids = shared_object.repository_rows.select(:id)
    rows_to_unlink = RepositoryRow.joins("LEFT JOIN repository_row_connections \
                                         ON repository_rows.id = repository_row_connections.parent_id \
                                         OR repository_rows.id = repository_row_connections.child_id")
                                  .where("repository_row_connections.parent_id IN (?) \
                                         OR repository_row_connections.child_id IN (?)",
                                         repository_rows_ids,
                                         repository_rows_ids)
                                  .joins(:repository)
                                  .where.not(repositories: { team: teams_ids })
                                  .select(:id)

    RepositoryRowConnection.where("(repository_row_connections.parent_id IN (?) \
                                   AND repository_row_connections.child_id IN (?)) \
                                   OR (repository_row_connections.parent_id IN (?) \
                                   AND repository_row_connections.child_id IN (?))",
                                  repository_rows_ids,
                                  rows_to_unlink,
                                  rows_to_unlink,
                                  repository_rows_ids)
                           .destroy_all
  end
end
