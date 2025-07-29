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
      if team_assignments.loaded?
        team_assignments.find { |ta| ta.team_id == (current_team || team).id }&.user_role_id
      else
        team_assignments.where(team_id: (current_team || team).id).pick(:user_role_id)
      end
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
