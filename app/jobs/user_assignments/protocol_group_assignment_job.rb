# frozen_string_literal: true

module UserAssignments
  class ProtocolGroupAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(team, protocols, assigned_by)
      @team = team
      @assigned_by = assigned_by

      ActiveRecord::Base.transaction do
        team.users.where.not(id: assigned_by).find_each do |user|
          user_assignment = UserAssignment.find_or_initialize_by(
            user: user,
            assignable: protocols
          )

          next if user_assignment.manually_assigned?

          user_assignment.update!(
            user_role: protocol.default_public_user_role || UserRole.find_predefined_viewer_role,
            assigned_by: @assigned_by
          )
        end
      end
    end
  end
end
