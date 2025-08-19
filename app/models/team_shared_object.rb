# frozen_string_literal: true

class TeamSharedObject < ApplicationRecord
  enum permission_level: Extends::SHARED_OBJECTS_PERMISSION_LEVELS.except(:not_shared)

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

  # ifs needed for StorageLocations, which currently do not have assignments
  after_update :update_assignments, if: -> { shared_object.respond_to?(:user_assignments) }
  before_destroy :unassign_unshared_items, if: -> { shared_object.is_a?(Repository) }
  before_destroy :unlink_unshared_items, if: -> { shared_object.is_a?(Repository) }
  after_destroy :destroy_assignments, if: -> { shared_object.respond_to?(:user_assignments) }

  private

  def unassign_unshared_items
    return if shared_object.shared_read? || shared_object.shared_write?

    MyModuleRepositoryRow.joins(my_module: { experiment: { project: :team } })
                         .joins(repository_row: :repository)
                         .where(my_module: { experiment: { projects: { team: team } } })
                         .where(repository_rows: { repository: shared_object })
                         .destroy_all
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

  def update_assignments
    return unless saved_change_to_permission_level? && permission_level == 'shared_read'

    shared_object.demote_all_sharing_assignments_to_viewer!(for_team: team)
  end

  def destroy_assignments
    shared_object.destroy_all_sharing_assignments!(for_team: team)
  end

  def team_cannot_be_the_same
    errors.add(:team_id, :same_team) if shared_object.team.id == team_id
  end
end
