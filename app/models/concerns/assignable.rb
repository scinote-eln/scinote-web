# frozen_string_literal: true

module Assignable
  extend ActiveSupport::Concern

  included do
    include Canaid::Helpers::PermissionsHelper

    attr_accessor :skip_user_assignments

    has_many :user_assignments, as: :assignable, dependent: :destroy
    has_many :user_group_assignments, as: :assignable, dependent: :destroy
    has_many :team_assignments, as: :assignable, dependent: :destroy
    has_many :automatic_user_assignments, -> { automatically_assigned },
             as: :assignable,
             class_name: 'UserAssignment',
             inverse_of: :assignable
    has_many :automatic_user_group_assignments, -> { automatically_assigned },
             as: :assignable,
             class_name: 'UserGroupAssignment',
             inverse_of: :assignable
    has_many :automatic_team_assignments, -> { automatically_assigned },
             as: :assignable,
             class_name: 'TeamAssignment',
             inverse_of: :assignable

    scope :readable_by_user, lambda { |user, teams = user.permission_team|
      read_permission = "::#{self.class.to_s.split('::').first}Permissions".constantize::READ
      with_user_assignments = joins(user_assignments: :user_role)
                              .where(user_assignments: { user: user, team: teams })

      # direct user assignments take precedence over group assignments, thus skipping objects that already have user assignments.
      with_group_assignments = left_outer_joins(user_group_assignments: [:user_role, { user_group: :users }], team_assignments: :user_role)
                               .where.not(id: with_user_assignments)

      with_granted_user_permissions = with_user_assignments.where('? = ANY(user_roles.permissions)', read_permission)
      with_granted_group_permissions = with_group_assignments
                                       .where(user_group_assignments: { assignable: self, user_groups: { users: user } })
                                       .where('? = ANY(user_roles.permissions)', read_permission)
                                       .or(
                                         with_group_assignments
                                         .where(team_assignments: { assignable: self, team: teams })
                                         .where('? = ANY(user_roles.permissions)', read_permission)
                                       )
                                       .distinct

      shared_objects =
        if klass.new.respond_to?(:shared_with?)
          joins(team_shared_objects: :team)
            .where(team_shared_objects: { team: teams })
            .where(teams: { id: Team.with_granted_permissions(user, TeamPermissions::MANAGE) })
        else
          none
        end

      globally_shared_objects =
        if klass.new.respond_to?(:permission_level)
          where(permission_level: %i(shared_read shared_write))
        else
          none
        end

      where(id: with_granted_user_permissions.reselect(:id))
        .or(where(id: with_granted_group_permissions.reselect(:id)))
        .or(where(id: shared_objects.select(:id)))
        .or(where(id: globally_shared_objects.select(:id)))
    }

    scope :managable_by_user, lambda { |user, teams = user.permission_team|
      manage_permission = "::#{self.class.to_s.split('::').first}Permissions".constantize::MANAGE
      with_user_assignments = joins(user_assignments: :user_role)
                              .where(user_assignments: { user: user, team: teams })

      # direct user assignments take precedence over group assignments, thus skipping objects that already have user assignments.
      with_group_assignments = left_outer_joins(user_group_assignments: [:user_role, { user_group: :users }], team_assignments: :user_role)
                               .where.not(id: with_user_assignments)

      with_granted_user_permissions = with_user_assignments.where('? = ANY(user_roles.permissions)', manage_permission)
      with_granted_group_permissions = with_group_assignments
                                       .where(user_group_assignments: { assignable: self, user_groups: { users: user } })
                                       .where('? = ANY(user_roles.permissions)', manage_permission)
                                       .or(
                                         with_group_assignments
                                         .where(team_assignments: { assignable: self, team: teams })
                                         .where('? = ANY(user_roles.permissions)', manage_permission)
                                       )
                                       .distinct
      where(id: with_granted_user_permissions.reselect(:id))
        .or(where(id: with_granted_group_permissions.reselect(:id)))
    }

    after_create :create_users_assignments

    def users
      direct_user_ids = user_assignments.select(:user_id)

      # Users through user_groups assigned
      group_user_ids = UserGroupMembership.joins(:user_group)
                                          .where(user_group_id: UserGroupAssignment.where(assignable: self).select(:user_group_id))
                                          .select(:user_id)

      # Users through teams assigned
      team_user_ids = UserAssignment.where(assignable_id: team_assignments.select(:team_id), assignable_type: 'Team')
                                    .select(:user_id)

      User.where(id: direct_user_ids).or(User.where(id: group_user_ids)).or(User.where(id: team_user_ids))
    end

    def default_public_user_role_id(current_team = nil)
      team_assignments.where(team_id: (current_team || team).id).pick(:user_role_id)
    end

    def has_permission_children?
      false
    end

    def role_for_user(user)
      user_assignments.find_by(user: user)&.user_role
    end

    def manually_assigned_users
      User.joins(:user_assignments).where(user_assignments: { assigned: :manually, assignable: self })
    end

    def assigned_users
      User.joins(:user_assignments).where(user_assignments: { assignable: self })
    end

    def top_level_assignable?
      self.class.name.in?(Extends::TOP_LEVEL_ASSIGNABLES)
    end

    private

    def after_user_assignment_changed(user_assignment = nil)
      # Optional, redefine in the assignable model.
      # Will be called when an assignment is changed (save/destroy) for the assignable model.
    end

    def after_user_group_assignment_changed(user_group_assignment = nil)
      # Optional, redefine in the assignable model.
      # Will be called when an assignment is changed (save/destroy) for the assignable model.
    end

    def create_users_assignments
      return if skip_user_assignments

      role = if top_level_assignable?
               UserRole.find_predefined_owner_role
             else
               permission_parent.user_assignments.find_by(user: created_by).user_role
             end

      UserAssignment.create!(
        user: created_by,
        assignable: self,
        assigned: top_level_assignable? ? :manually : :automatically,
        user_role: role
      )

      UserAssignments::GenerateUserAssignmentsJob.perform_later(self, created_by.id)
    end
  end
end
