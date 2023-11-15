# frozen_string_literal: true

module UserAssignments
  class ProjectGroupUnAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(project)
      ActiveRecord::Base.transaction do
        user_assignments = project.user_assignments.where(assigned: :automatically)
        users = User.where(id: user_assignments.select(:user_id))

        remove_users_from_my_modules(project, users)
        remove_users_from_experiments(project, users)
        user_assignments.destroy_all
      end
    end

    def remove_users_from_experiments(project, users)
      experiments = project.experiments.joins(:user_assignments).where(user_assignments: { user: users })
      # rubocop:disable Rails/SkipsModelValidations
      UserAssignment.where(assignable_type: 'Experiment', assignable_id: experiments, user: users).delete_all
      experiments.update_all(updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations
    end

    def remove_users_from_my_modules(project, users)
      my_modules = MyModule.joins(:user_assignments, experiment: :project)
                           .where(user_assignments: { user: users })
                           .where(projects: project)
      # rubocop:disable Rails/SkipsModelValidations
      UserMyModule.where(user: users, my_module: my_modules).delete_all # remove designated users
      UserAssignment.where(assignable_type: 'MyModule', assignable_id: my_modules, user: users).delete_all
      my_modules.update_all(updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
