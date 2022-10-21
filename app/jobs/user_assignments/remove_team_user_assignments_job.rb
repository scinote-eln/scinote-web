# frozen_string_literal: true

module UserAssignments
  class RemoveTeamUserAssignmentsJob < ApplicationJob
    queue_as :high_priority

    def perform(user, team)
      ActiveRecord::Base.transaction do
        RemoveTeamUserAssignmentsService.new(user, team).call
      end
    end
  end
end
