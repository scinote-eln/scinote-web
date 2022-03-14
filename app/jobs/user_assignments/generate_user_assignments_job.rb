# frozen_string_literal: true

module UserAssignments
  class GenerateUserAssignmentsJob < ApplicationJob
    queue_as :high_priority

    def perform(object, assigned_by)
      @assigned_by = assigned_by
      ActiveRecord::Base.transaction do
        case object
        when Experiment
          assign_users_to_experiment(object)
        when MyModule
          assign_users_to_my_module(object)
        end
      end
    end

    private

    def assign_users_to_experiment(experiment)
      project = experiment.project
      project.user_assignments.find_each do |user_assignment|
        create_or_update_user_assignment(user_assignment, experiment)
      end
    end

    def assign_users_to_my_module(my_module)
      experiment = my_module.experiment
      experiment.user_assignments.find_each do |user_assignment|
        create_or_update_user_assignment(user_assignment, my_module)
      end
    end

    def create_or_update_user_assignment(parent_user_assignment, object)
      user_role = parent_user_assignment.user_role
      user = parent_user_assignment.user
      new_user_assignment = UserAssignment.find_or_initialize_by(user: user, assignable: object)
      return if new_user_assignment.manually_assigned?

      new_user_assignment.user_role = user_role
      new_user_assignment.assigned_by = @assigned_by
      new_user_assignment.assigned = :automatically
      new_user_assignment.save!
    end
  end
end
