# frozen_string_literal: true

module UserAssignments
  class GenerateUserAssignmentsJob < ApplicationJob
    queue_as :high_priority

    def perform(object, assigned_by_id)
      @assigned_by = User.find_by(id: assigned_by_id)
      ActiveRecord::Base.transaction do
        case object
        when Experiment
          assign_users_to_experiment(object)
        when MyModule
          assign_users_to_my_module(object)
        when Repository
          assign_users_to_repository(object)
        when Protocol
          assign_users_to_protocol(object)
        when Report
          assign_users_to_report(object)
        end
      end
    end

    private

    def assign_users_to_experiment(experiment)
      project = experiment.project
      project.user_assignments.find_each do |user_assignment|
        create_or_update_user_assignment(user_assignment, experiment)
      end

      project.user_group_assignments.find_each do |user_group_assignment|
        create_or_update_user_assignment(user_group_assignment, experiment)
      end
    end

    def assign_users_to_my_module(my_module)
      experiment = my_module.experiment
      experiment.user_assignments.find_each do |user_assignment|
        create_or_update_user_assignment(user_assignment, my_module)
      end

      experiment.user_group_assignments.find_each do |user_group_assignment|
        create_or_update_user_assignment(user_group_assignment, my_module)
      end
    end

    def assign_users_to_repository(repository)
      team = repository.team
      team.user_assignments.find_each do |user_assignment|
        create_or_update_user_assignment(user_assignment, repository)
      end
    end

    def assign_users_to_protocol(protocol)
      if protocol.parent_id && protocol.in_repository_draft?
        Protocol.transaction(requires_new: true) do
          protocol.parent.user_assignments.find_each do |user_assignment|
            protocol.parent.sync_child_protocol_user_assignment(user_assignment, protocol.id)
          end

          protocol.parent.user_group_assignments.find_each do |user_group_assignment|
            protocol.parent.sync_child_protocol_user_assignment(user_group_assignment, protocol.id)
          end
        end

        return
      end

      return unless protocol.visible?

      protocol.create_or_update_public_user_assignments!(@assigned_by)
    end

    def assign_users_to_report(report)
      team = report.team
      team.user_assignments.find_each do |user_assignment|
        create_or_update_user_assignment(user_assignment, report)
      end
    end

    def create_or_update_user_assignment(parent_assignment, object)
      is_group = parent_assignment.respond_to?(:user_group)
      user_role = parent_assignment.user_role
      target_id = is_group ? parent_assignment.user_group_id : parent_assignment.user_id
      new_assignment = if is_group
                         UserGroupAssignment.find_or_initialize_by(user_group_id: target_id, assignable: object, team: object.team)
                       else
                         UserAssignment.find_or_initialize_by(user_id: target_id, assignable: object)
                       end

      return if new_assignment.manually_assigned?

      new_assignment.user_role = user_role
      new_assignment.assigned_by = @assigned_by
      new_assignment.assigned = :automatically
      new_assignment.save!
    end
  end
end
