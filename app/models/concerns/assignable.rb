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

    after_create :create_user_assignments!, unless: -> { skip_user_assignments }

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

    def reset_all_users_assignments!(assigned_by)
      user_assignments.destroy_all
      user_group_assignments.destroy_all
      team_assignments.destroy_all
      create_user_assignments!(assigned_by)
    end

    def manually_assigned_users
      User.joins(:user_assignments).where(user_assignments: { assigned: :manually, assignable: self })
    end

    def assigned_users(team)
      team_assignment = team_assignments.find_by(team: team)

      users = User.where(id: user_assignments.where(team: team))
      users = users.or(User.where(id: team_assignment.team.users.select(:id))) if team_assignment

      users
    end

    def assigned_users_with_roles(team)
      users = []
      user_assignments.where(team: team).includes(:user, :user_role).find_each do |ua|
        users << {
          user: ua.user,
          role: ua.user_role,
          type: :user_assignment
        }
      end

      team_assignment = team_assignments.find_by(team: team)
      if team_assignment
        User.where.not(id: user_assignments.select(:user_id)).where(id: team_assignment.team.users.select(:id)).find_each do |user|
          users << {
            user: user,
            role: team_assignment.user_role,
            type: :team_assignment
          }
        end
      end

      users
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

    def create_user_assignments!(user = created_by)
      # First create initial assignments for the object's creator
      if top_level_assignable?
        user_assignments.create!(user: user, assigned: :manually, user_role: UserRole.find_predefined_owner_role)
      else
        parent_assignment = permission_parent.user_assignments.find_by(user: user, team: team)
        if parent_assignment.present?
          user_assignments.create!(user: user, user_role: parent_assignment.user_role)
        else
          parent_group_assignments = permission_parent.user_group_assignments
                                                      .joins(user_group: :user_group_memberships)
                                                      .where(team: team, user_groups: { user_group_memberships: { user_id: user.id } })
          if parent_group_assignments.present?
            parent_group_assignments.each do |parent_group_assignment|
              user_group_assignments.create!(user_group: parent_group_assignment.user_group, user_role: parent_group_assignment.user_role)
            end
          else
            parent_team_assignment = permission_parent.team_assignments.find_by(team: team)
            team_assignments.create!(team: team, user_role: parent_team_assignment.user_role) if parent_team_assignment.present?
          end
        end
      end

      # Generate assignments for the rest of users in the background
      UserAssignments::GenerateUserAssignmentsJob.perform_later(self, user.id)
    end
  end
end
