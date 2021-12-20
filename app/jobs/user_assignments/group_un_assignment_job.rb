# frozen_string_literal: true

module UserAssignments
  class GroupUnAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(project)
      ActiveRecord::Base.transaction do
        user_assignments = project.user_assignments.where(assigned: :automatically)
        users = User.find(user_assignments.pluck(:user_id))

        remove_users_from_experiments_and_my_modules(project, users)
        UserAssignment.where(user: users, assignable: project).destroy_all
      end
    end

    def remove_users_from_experiments_and_my_modules(project, users)
      project.experiments.each do |experiment|
        experiment.my_modules.each do |my_module|
          UserAssignment.where(user: users, assignable: my_module).destroy_all
        end
        UserAssignment.where(user: users, assignable: experiment).destroy_all
      end
    end
  end
end
