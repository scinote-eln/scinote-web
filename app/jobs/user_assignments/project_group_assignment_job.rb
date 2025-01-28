# frozen_string_literal: true

module UserAssignments
  class ProjectGroupAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(project, assigned_by_id, user_id = nil)
      @assigned_by = User.find_by(id: assigned_by_id)
      # If user_id is proved - assign only that specific user, otherwise assign all team users
      @users = user_id ? User.where(id: user_id) : project.team.users

      return unless project.visible?

      ActiveRecord::Base.transaction do
        @users.find_each do |user|
          user_assignment = UserAssignment.find_or_initialize_by(
            user: user,
            assignable: project
          )

          next if user_assignment.manually_assigned?

          user_assignment.update!(
            user_role: project.default_public_user_role || UserRole.find_predefined_viewer_role,
            assigned_by: @assigned_by
          )

          next unless project.experiments.any?

          # make sure all related experiments and my modules are assigned
          UserAssignments::PropagateAssignmentJob.perform_later(
            project,
            user.id,
            project.default_public_user_role || UserRole.find_predefined_viewer_role,
            @assigned_by&.id
          )
        end
      end
    end
  end
end
