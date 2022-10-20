# frozen_string_literal: true

module UserAssignments
  class UpdateTeamUserAssignmentsJob < ApplicationJob
    queue_as :high_priority

    def perform(user, team, user_role)
      ActiveRecord::Base.transaction do
        UpdateTeamUserAssignmentsService.new(user, team, user_role).call
      end
    end
  end
end
