# frozen_string_literal: true

module UserAssignments
  class RemoveTeamUserAssignmentsJob < BaseJob
    def perform(team_user_assignment, assigner_id:)
      unassigned_by = User.find_by(id: assigner_id)

      Rails.logger.info "Enqueued by User(#{assigner_id}) for Team(#{team_user_assignment.assignable_id})\n"

      ActiveRecord::Base.transaction do
        RemoveTeamUserAssignmentsService.new(team_user_assignment, unassigned_by).call
        team_user_assignment.destroy!
      end
    end
  end
end
