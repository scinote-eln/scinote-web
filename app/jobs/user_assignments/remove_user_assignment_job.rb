# frozen_string_literal: true

module UserAssignments
  class RemoveUserAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(user, team)
      ActiveRecord::Base.transaction do
        team.projects.each do |project|
          UserAssignments::PropagateAssignmentJob
            .perform_now(project, user, nil, nil, destroy: true, remove_from_team: true)
        end
      end
    end
  end
end
