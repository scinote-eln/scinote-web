# frozen_string_literal: true

class UserAssignment < ApplicationRecord
  attr_accessor :assign

  before_validation :set_assignable_team
  after_create :assign_team_child_objects, if: -> { assignable.is_a?(Team) }
  after_update :update_team_children_assignments, if: -> { assignable.is_a?(Team) && saved_change_to_user_role_id? }
  before_destroy :unassign_team_child_objects, if: -> { assignable.is_a?(Team) }
  after_destroy :call_user_assignment_changed_hook
  after_destroy :remove_user_group_memberships, if: -> { assignable.is_a?(Team) }
  after_save :call_user_assignment_changed_hook

  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :user_role
  belongs_to :user
  belongs_to :team
  belongs_to :assigned_by, class_name: 'User', optional: true

  enum :assigned, { automatically: 0, manually: 1 }, suffix: true

  validates :user, uniqueness: { scope: %i(assignable team_id) }

  scope :with_permission, ->(permission) { joins(:user_role).where('? = ANY(user_roles.permissions)', permission) }
  scope :as_owners, -> { where(user_role: UserRole.find_predefined_owner_role) }
  scope :as_normal_users, -> { where(user_role: UserRole.find_predefined_normal_user_role) }
  scope :as_viewers, -> { where(user_role: UserRole.find_predefined_viewer_role) }

  def last_assignable_owner?
    assignable_owners.count == 1 && user_role.owner?
  end

  def remove_user_group_memberships
    user.user_group_memberships
        .joins(:user_group)
        .where(user_group: { team: assignable })
        .destroy_all
  end

  def last_with_permission?(permission, assigned: nil)
    return false if user_role.permissions.exclude?(permission)

    user_assignments =
      assignable.user_assignments.joins(:user_role)
                .where.not(user: user)
                .with_permission(permission)

    user_assignments = user_assignments.where(assigned: assigned) if assigned

    user_assignments.none?
  end

  def user_name_with_role
    "#{user.name} - #{user_role.name}"
  end

  private

  def set_assignable_team
    self.team ||= (assignable.is_a?(Team) ? assignable : assignable.team)
  end

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
