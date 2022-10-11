# frozen_string_literal: true

module UserAssignments
  class RemoveTeamUserAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(user, team)
      ActiveRecord::Base.transaction do
        RemoveTeamUserAssignmentService.new(user, team).call
      end
    end
  end
end
