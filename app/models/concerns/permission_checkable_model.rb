# frozen_string_literal: true

module PermissionCheckableModel
  extend ActiveSupport::Concern

  included do
    include PermissionExtends

    scope :with_granted_permissions, lambda { |user, permissions, teams = user.permission_team|
      with_user_assignments = joins(user_assignments: :user_role)
                              .where(user_assignments: { user: user, team: teams })
      # direct user assignments take precedence over group assignments, thus skipping objects that already have user assignments.
      with_group_assignments = left_outer_joins(user_group_assignments: [:user_role, { user_group: :users }], team_assignments: :user_role)
                               .where.not(id: with_user_assignments)

      with_granted_user_permissions = with_user_assignments.where('user_roles.permissions @> ARRAY[?]::varchar[]', permissions)
      with_granted_group_permissions = with_group_assignments
                                       .where(user_group_assignments: { assignable: self, user_groups: { users: user }, team: teams })
                                       .where('user_roles.permissions @> ARRAY[?]::varchar[]', permissions)
                                       .or(
                                         with_group_assignments
                                         .where(team_assignments: { assignable: self, team: teams })
                                         .where('user_roles_team_assignments.permissions @> ARRAY[?]::varchar[]', permissions)
                                       )
                                       .distinct
      where(id: with_granted_user_permissions.reselect(:id))
        .or(where(id: with_granted_group_permissions.reselect(:id)))
    }

    def self.permission_class
      self
    end
  end

  def permission_granted?(user, permission, permission_team = user.permission_team)
    return true if user_assignments.joins(:user_role)
                                   .where(user: user, team: permission_team)
                                   .exists?(['user_roles.permissions @> ARRAY[?]::varchar[]', [permission]])

    user_roles = UserRole.left_outer_joins(:team_assignments, user_group_assignments: { user_group: :users })
    user_roles.where(user_group_assignments: { assignable: self, user_groups: { users: user } })
              .or(user_roles.where(team_assignments: { assignable: self, team: permission_team }))
              .exists?(['user_roles.permissions @> ARRAY[?]::varchar[]', [permission]])
  end

  def readable_by_user?(user)
    permission_granted?(user, "::#{self.class.to_s.split('::').first}Permissions".constantize::READ)
  end
end
