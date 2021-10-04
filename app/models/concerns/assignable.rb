# frozen_string_literal: true

module Assignable
  extend ActiveSupport::Concern

  included do
    include Canaid::Helpers::PermissionsHelper

    has_many :user_assignments, as: :assignable, dependent: :destroy

    default_scope { includes(user_assignments: :user_role) }

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

    after_create_commit do
      UserAssignment.create!(
        user: created_by,
        assignable: self,
        assigned: :manually, # we set this to manually since was the user action to create the item
        user_role: UserRole.find_by(name: I18n.t('user_roles.predefined.owner'))
      )

      # project is top level, so we do not need to create any more assignments for it
      unless self.class.instance_of?(Project)
        UserAssignments::GenerateUserAssignmentsJob.perform_later(self, created_by)
      end
    end
  end
end
