# frozen_string_literal: true

module UserAssignments
  class RemoveTeamUserAssignmentsJob < ApplicationJob
    queue_as :high_priority

    def perform(team_user_assignment)
      ActiveRecord::Base.transaction do
        RemoveTeamUserAssignmentsService.new(team_user_assignment).call
      end
    end
  end
end
