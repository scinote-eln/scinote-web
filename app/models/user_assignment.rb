# frozen_string_literal: true

class UserAssignment < ApplicationRecord
  attr_accessor :assign

  before_validation -> { self.team ||= (assignable.is_a?(Team) ? assignable : assignable.team) }
  after_create :assign_team_child_objects, if: -> { assignable.is_a?(Team) }
  after_update :update_team_children_assignments, if: -> { assignable.is_a?(Team) && saved_change_to_user_role_id? }
  before_destroy :unassign_team_child_objects, if: -> { assignable.is_a?(Team) }
  after_destroy :call_user_assignment_changed_hook
  after_save :call_user_assignment_changed_hook

  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :user_role
  belongs_to :user
  belongs_to :team
  belongs_to :assigned_by, class_name: 'User', optional: true

  enum assigned: { automatically: 0, manually: 1 }, _suffix: true

  validates :user, uniqueness: { scope: %i(assignable team_id) }

  def last_assignable_owner?
    assignable_owners.count == 1 && user_role.owner?
  end

  def last_with_permission?(permission)
    return false if user_role.permissions.exclude?(permission)

    assignable.user_assignments.joins(:user_role)
              .where.not(user: user)
              .where('? = ANY(user_roles.permissions)', permission)
              .none?
  end

  private

  def call_user_assignment_changed_hook
    assignable.__send__(:after_user_assignment_changed, self)
  end

  def assign_team_child_objects
    UserAssignments::CreateTeamUserAssignmentsService.new(self).call
  end

  def update_team_children_assignments
    UserAssignments::UpdateTeamUserAssignmentsService.new(self).call
  end

  def unassign_team_child_objects
    UserAssignments::RemoveTeamUserAssignmentsService.new(self).call
  end

  def assignable_owners
    @assignable_owners ||= assignable.user_assignments
                                     .includes(:user_role)
                                     .where(user_roles: { name: I18n.t('user_roles.predefined.owner') })
  end
end
