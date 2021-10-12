# frozen_string_literal: true

module UserAssignments
  class RemoveUserAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(user, team)
      ActiveRecord::Base.transaction do
        team.projects.each do |project|
          UserAssignments::PropagateAssignmentJob.perform_now(project, user, nil, nil, destroy: true)
          UserAssignment.where(user: user, assignable: project).destroy_all
        end
      end
    end
  end
end
