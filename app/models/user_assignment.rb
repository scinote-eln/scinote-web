# frozen_string_literal: true

class UserAssignment < ApplicationRecord
  before_validation -> { self.team ||= (assignable.is_a?(Team) ? assignable : assignable.team) }
  after_create :assign_shared_inventories, if: -> { assignable.is_a?(Team) }
  after_create :assign_public_projects, if: -> { assignable.is_a?(Team) }
  after_update :update_team_children_assignments, if: -> { assignable.is_a?(Team) && saved_change_to_user_role_id? }
  before_destroy :unassign_shared_inventories, if: -> { assignable.is_a?(Team) }
  before_destroy :unassign_team_child_objects, if: -> { assignable.is_a?(Team) }

  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :user_role
  belongs_to :user
  belongs_to :team
  belongs_to :assigned_by, class_name: 'User', optional: true

  enum assigned: { automatically: 0, manually: 1 }, _suffix: true

  validates :user, uniqueness: { scope: %i(assignable team_id) }

  private

  def assign_shared_inventories
    viewer_role = UserRole.find_by(name: UserRole.public_send('viewer_role').name)
    normal_user_role = UserRole.find_by(name: UserRole.public_send('normal_user_role').name)

    assignable.team_shared_repositories.find_each do |team_shared_repository|
      assignable.repository_sharing_user_assignments.create!(
        user: user,
        user_role: team_shared_repository.shared_write? ? normal_user_role : viewer_role,
        assignable: team_shared_repository.shared_object
      )
    end

    Repository.globally_shared.find_each do |repository|
      assignable.repository_sharing_user_assignments.create!(
        user: user,
        user_role: repository.shared_write? ? normal_user_role : viewer_role,
        assignable: repository
      )
    end
  end

  def assign_public_projects
    assignable.projects.visible.find_each do |project|
      UserAssignments::GroupAssignmentJob.perform_later(
        assignable,
        project,
        assigned_by
      )
    end
  end

  def update_team_children_assignments
    UserAssignments::UpdateTeamUserAssignmentService.new(user, assignable, user_role).call
  end

  def unassign_shared_inventories
    assignable.repository_sharing_user_assignments.where(user: user).find_each(&:destroy!)
  end

  def unassign_team_child_objects
    UserAssignments::RemoveTeamUserAssignmentService.new(user, assignable).call
  end
end
