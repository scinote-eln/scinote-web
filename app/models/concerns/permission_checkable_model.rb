# frozen_string_literal: true

module PermissionCheckableModel
  extend ActiveSupport::Concern

  included do
    include PermissionExtends

    scope :with_granted_permissions, lambda { |user, permissions, teams = user.permission_team|
      with_user_assignments = joins(user_assignments: :user_role)
                              .where(user_assignments: { user: user, team_id: teams })
      with_granted_user_permissions = with_user_assignments.where('user_roles.permissions @> ARRAY[?]::varchar[]', permissions)

      # direct user assignments take precedence over group assignments, thus skipping objects that already have user assignments.
      with_granted_group_permissions = joins(user_group_assignments: [:user_role, { user_group: :users }])
                                       .where.not(id: with_user_assignments)
                                       .where(user_group_assignments: { assignable: self, user_groups: { users: user }, team_id: teams })
                                       .where('user_roles.permissions @> ARRAY[?]::varchar[]', permissions)

      with_granted_team_permissions = joins(team_assignments: :user_role)
                                      .where.not(id: with_user_assignments)
                                      .where(team_assignments: { assignable: self, team_id: teams })
                                      .where('user_roles.permissions @> ARRAY[?]::varchar[]', permissions)

      where(id: from("(#{with_granted_user_permissions.to_sql} " \
                     "UNION " \
                     "#{with_granted_group_permissions.to_sql} " \
                     "UNION " \
                     "#{with_granted_team_permissions.to_sql} " \
                     ") AS #{table_name}", table_name)
                    .reselect(:id))
    }

    scope :readable_by_user, lambda { |user, teams = user.permission_team|
      read_permission = "::#{self.class.to_s.split('::').first}Permissions".constantize::READ
      with_granted_permissions(user, read_permission, teams)
    }

    scope :managable_by_user, lambda { |user, teams = user.permission_team|
      manage_permission = "::#{self.class.to_s.split('::').first}Permissions".constantize::MANAGE
      with_granted_permissions(user, manage_permission, teams)
    }

    def self.permission_class
      self
    end
  end

  def permission_granted?(user, permission, permission_team = user.permission_team)
    if user_assignments.exists?(user: user, team: permission_team)
      return user_assignments.joins(:user_role)
                             .where(user: user, team: permission_team)
                             .exists?(['user_roles.permissions @> ARRAY[?]::varchar[]', [permission]])
    end

    team_roles = UserRole.joins(:team_assignments)
                         .where(team_assignments: { assignable: self, team: permission_team })
    group_roles = UserRole.joins(user_group_assignments: { user_group: :users })
                          .where(user_group_assignments: { assignable: self, user_groups: { users: user }, team: permission_team })

    UserRole.from(
      "(#{team_roles.to_sql} UNION #{group_roles.to_sql}) AS user_roles",
      :user_roles
    ).exists?(['user_roles.permissions @> ARRAY[?]::varchar[]', [permission]])
  end

  def readable_by_user?(user)
    permission_granted?(user, "::#{self.class.to_s.split('::').first}Permissions".constantize::READ)
  end
end
