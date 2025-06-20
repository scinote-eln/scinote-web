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

    scope :readable_by_user, lambda { |user|
      joins("INNER JOIN user_assignments reading_user_assignments " \
            "ON reading_user_assignments.assignable_type = '#{base_class.name}' " \
            "AND reading_user_assignments.assignable_id = #{table_name}.id " \
            "INNER JOIN user_roles reading_user_roles " \
            "ON reading_user_assignments.user_role_id = reading_user_roles.id")
        .where(reading_user_assignments: { user_id: user.id })
        .where('? = ANY(reading_user_roles.permissions)', "::#{self.class.to_s.split('::').first}Permissions".constantize::READ)
    }

    scope :managable_by_user, lambda { |user|
      joins("INNER JOIN user_assignments managing_user_assignments " \
            "ON managing_user_assignments.assignable_type = '#{base_class.name}' " \
            "AND managing_user_assignments.assignable_id = #{table_name}.id " \
            "INNER JOIN user_roles managing_user_roles " \
            "ON managing_user_assignments.user_role_id = managing_user_roles.id")
        .where(managing_user_assignments: { user_id: user.id })
        .where('? = ANY(managing_user_roles.permissions)', "::#{self.class.to_s.split('::').first}Permissions".constantize::MANAGE)
    }

    scope :with_user_permission, lambda { |user, permission|
      joins("INNER JOIN user_assignments permission_checking_user_assignments " \
            "ON permission_checking_user_assignments.assignable_type = '#{base_class.name}' " \
            "AND permission_checking_user_assignments.assignable_id = #{table_name}.id " \
            "INNER JOIN user_roles permission_checking_user_roles " \
            "ON permission_checking_user_assignments.user_role_id = permission_checking_user_roles.id")
        .where(permission_checking_user_assignments: { user_id: user.id })
        .where('? = ANY(permission_checking_user_roles.permissions)', permission)
    }

    after_create :create_users_assignments

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
