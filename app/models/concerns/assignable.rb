# frozen_string_literal: true

module Assignable
  extend ActiveSupport::Concern

  included do
    include Canaid::Helpers::PermissionsHelper

    attr_accessor :skip_user_assignments

    has_many :user_assignments, as: :assignable, dependent: :destroy
    has_many :automatic_user_assignments, -> { automatically_assigned },
             as: :assignable,
             class_name: 'UserAssignment',
             inverse_of: :assignable

    scope :readable_by_user, lambda { |user|
      joins(user_assignments: :user_role)
        .where(user_assignments: { user: user })
        .where('? = ANY(user_roles.permissions)', "::#{self.class.to_s.split('::').first}Permissions".constantize::READ)
    }

    scope :managable_by_user, lambda { |user|
      joins(user_assignments: :user_role)
        .where(user_assignments: { user: user })
        .where('? = ANY(user_roles.permissions)', "::#{self.class.to_s.split('::').first}Permissions".constantize::MANAGE)
    }

    scope :with_user_permission, lambda { |user, permission|
      joins(user_assignments: :user_role)
        .where(user_assignments: { user: user })
        .where('? = ANY(user_roles.permissions)', permission)
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
