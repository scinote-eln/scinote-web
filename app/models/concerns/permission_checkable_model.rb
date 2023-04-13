# frozen_string_literal: true

module PermissionCheckableModel
  extend ActiveSupport::Concern

  included do
    include PermissionExtends

    scope :with_granted_permissions, lambda { |user, permissions|
      left_outer_joins(user_assignments: :user_role)
        .where(user_assignments: { user: user })
        .where('user_roles.permissions @> ARRAY[?]::varchar[]', permissions)
    }
  end

  def permission_granted?(user, permission)
    user_role_permissions = load_user_role_permissions(user)
    return false if user_role_permissions.blank?

    user_role_permissions.include?(permission)
  end

  private

  def load_user_role_permissions(user)
    if user_assignments.loaded?
      user_assignments.detect do |user_assignment|
        user_assignment.user == user && (is_a?(Team) || user_assignment.team == user.permission_team)
      end&.user_role&.permissions
    else
      load_criteria = is_a?(Team) ? { user: user } : { user: user, team: user.permission_team }
      user_assignments.find_by(load_criteria)&.user_role&.permissions
    end
  end
end
