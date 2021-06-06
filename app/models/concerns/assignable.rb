# frozen_string_literal: true

module Assignable
  extend ActiveSupport::Concern

  included do
    has_many :user_assignments, as: :assignable, dependent: :destroy

    default_scope { includes(user_assignments: :user_role) }

    after_create_commit do
      UserAssignments::GenerateUserAssignmentsJob.perform_later(self, created_by)
    end
  end
end
