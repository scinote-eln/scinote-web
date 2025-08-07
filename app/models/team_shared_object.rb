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
  after_destroy :destroy_assignments, if: -> { shared_object.respond_to?(:user_assignments) }

  private

  def update_assignments
    return unless saved_change_to_permission_level? && permission_level == 'shared_read'

    shared_object.user_assignments.where(team: team).update!(user_role: UserRole.find_predefined_viewer_role)
    shared_object.user_group_assignments.where(team: team).update!(user_role: UserRole.find_predefined_viewer_role)
    shared_object.team_assignments.where(team: team).update!(user_role: UserRole.find_predefined_viewer_role)
  end

  def destroy_assignments
    shared_object.user_assignments.where(team: team).destroy_all
    shared_object.user_group_assignments.where(team: team).destroy_all
    shared_object.team_assignments.where(team: team).destroy_all
  end

  def team_cannot_be_the_same
    errors.add(:team_id, :same_team) if shared_object.team.id == team_id
  end
end
