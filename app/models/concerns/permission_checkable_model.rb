# frozen_string_literal: true

module PermissionCheckableModel
  extend ActiveSupport::Concern

  def permission_granted?(user, permission)
    user_role_permissions = load_user_role_permissions(user)
    return false if user_role_permissions.blank?

    user_role_permissions.include?(permission)
  end

  private

  def load_user_role_permissions(user)
    user_role_permissions =
      if user_assignments.loaded?
        user_assignments.detect { |user_assignment| user_assignment.user == user }&.user_role&.permissions
      else
        user_assignments.find_by(user: user)&.user_role&.permissions
      end

    if user_role_permissions.blank? && permission_parent.present?
      user_role_permissions = permission_parent.load_user_role_permissions(user)
    end

    user_role_permissions
  end
end
