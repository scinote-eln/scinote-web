# frozen_string_literal: true

module Assignable
  extend ActiveSupport::Concern

  included do
    include Canaid::Helpers::PermissionsHelper

    has_many :user_assignments, as: :assignable, dependent: :destroy

    default_scope { includes(user_assignments: :user_role).distinct }

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

    after_create do
      role = if self.class == Project
               UserRole.find_by(name: I18n.t('user_roles.predefined.owner'))
             else
               permission_parent.user_assignments.find_by(user: created_by).user_role
             end

      UserAssignment.create!(
        user: created_by,
        assignable: self,
        assigned: :automatically,
        user_role: role
      )

      UserAssignments::GenerateUserAssignmentsJob.perform_later(self, created_by)
    end

    def role_for_user(user)
      user_assignments.find_by(user: user)&.user_role
    end
  end
end
