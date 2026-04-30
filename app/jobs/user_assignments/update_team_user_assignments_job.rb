# frozen_string_literal: true

module UserAssignments
  class UpdateTeamUserAssignmentsJob < BaseJob
    def perform(team_user_assignment, user_id:)
      Rails.logger.info "Enqueued by User(#{user_id}) for Team(#{team_user_assignment.assignable_id})\n"

      ActiveRecord::Base.transaction do
        UpdateTeamUserAssignmentsService.new(team_user_assignment).call
      end
    end
  end
end
