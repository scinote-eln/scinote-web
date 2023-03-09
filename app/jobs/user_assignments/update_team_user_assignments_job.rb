# frozen_string_literal: true

module UserAssignments
  class UpdateTeamUserAssignmentsJob < ApplicationJob
    queue_as :high_priority

    def perform(team_user_assignment)
      ActiveRecord::Base.transaction do
        UpdateTeamUserAssignmentsService.new(team_user_assignment).call
      end
    end
  end
end
