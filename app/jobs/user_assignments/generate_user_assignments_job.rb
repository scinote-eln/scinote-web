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
        when Project
          assign_team_admins_to_project(object)
        end
      end
    end

    private

    def assign_team_admins_to_project(project)
      # TEMPORARY UNTIL WE ADD TEAM USER ASSIGNMENTS
      # Assigns all team admins as owners of project

      User.joins(:user_teams).where(
        user_teams: { role: UserTeam.roles[:admin], team: project.team }
      ).find_each do |user|
        UserAssignment.find_or_create_by!(
          user: user,
          assignable: project,
          assigned: :manually, # we set this to manually since was the user action to create the item
          user_role: UserRole.find_by(name: I18n.t('user_roles.predefined.owner'))
        )
      end
    end

    def assign_users_to_experiment(experiment)
      project = experiment.project
      project.user_assignments.find_each do |user_assignment|
        create_or_update_user_assignment(user_assignment, experiment)
      end
    end

    def assign_users_to_my_module(my_module)
      project = my_module.experiment.project
      project.user_assignments.find_each do |user_assignment|
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
