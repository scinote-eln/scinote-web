# frozen_string_literal: true

module UserAssignments
  class PropagateAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(object, user, user_role, assigned_by, destroy: false)
      @user = user
      @user_role = user_role
      @assigned_by = assigned_by
      @destroy = destroy

      ActiveRecord::Base.transaction do
        if object.is_a? Project
          sync_experiments_user_associations(object)
        elsif object.is_a? Experiment
          sync_my_modules_user_assignments(object)
        end
      end
    end

    private

    def sync_experiments_user_associations(project)
      project.experiments.find_each do |experiment|
        if @destroy
          destroy_user_assignment(experiment)
        else
          create_or_update_user_assignment(experiment)
        end

        sync_my_modules_user_assignments(experiment)
      end
    end

    def sync_my_modules_user_assignments(experiment)
      experiment.my_modules.find_each do |my_module|
        if @destroy
          destroy_user_assignment(my_module)
        else
          create_or_update_user_assignment(my_module)
        end
      end
    end

    def create_or_update_user_assignment(object)
      user_assignment = UserAssignment.find_or_initialize_by(user: @user, assignable: object)
      user_assignment.user_role = @user_role
      user_assignment.assigned_by = @assigned_by
      user_assignment.save!
    end

    def destroy_user_assignment(object)
      UserAssignment.find_by(user: @user, assignable: object).destroy_all
    end
  end
end
