# frozen_string_literal: true

class UserAssignment < ApplicationRecord
  before_validation -> { self.team ||= (assignable.is_a?(Team) ? assignable : assignable.team) }
  after_create :assign_team_child_objects, if: -> { assignable.is_a?(Team) }
  after_update :update_team_children_assignments, if: -> { assignable.is_a?(Team) && saved_change_to_user_role_id? }
  before_destroy :unassign_team_child_objects, if: -> { assignable.is_a?(Team) }

  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :user_role
  belongs_to :user
  belongs_to :team
  belongs_to :assigned_by, class_name: 'User', optional: true

  enum assigned: { automatically: 0, manually: 1 }, _suffix: true

  validates :user, uniqueness: { scope: %i(assignable team_id) }

  private

  def assign_team_child_objects
    UserAssignments::CreateTeamUserAssignmentsService.new(self).call
  end

  def update_team_children_assignments
    UserAssignments::UpdateTeamUserAssignmentsService.new(self).call
  end

  def unassign_team_child_objects
    UserAssignments::RemoveTeamUserAssignmentsService.new(self).call
  end
end
