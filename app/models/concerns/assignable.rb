# frozen_string_literal: true

module Assignable
  extend ActiveSupport::Concern

  included do
    has_many :user_assignments, as: :assignable, dependent: :destroy

    default_scope { includes(user_assignments: :user_role) }

    after_create_commit do
      UserAssignment.create!(
        user: created_by,
        assignable: self,
        user_role: UserRole.find_by(name: I18n.t('user_roles.predefined.owner'))
      )

      UserAssignments::GenerateUserAssignmentsJob.perform_later(self, created_by)
    end
  end
end
