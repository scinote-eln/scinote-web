# frozen_string_literal: true

module UserAssignments
  class GenerateUserAssignmentsJob < ApplicationJob
    queue_as :high_priority

    def perform(object, assigned_by_id)
      @assigned_by = User.find_by(id: assigned_by_id)
      ActiveRecord::Base.transaction do
        case object
        when Experiment
          assign_to_experiment(object)
        when MyModule
          assign_to_my_module(object)
        when Protocol
          assign_to_protocol(object)
        when Report
          assign_to_report(object)
        end
      end
    end

    private

    def assign_to_experiment(experiment)
      project = experiment.project
      project.user_assignments.find_each do |assignment|
        create_or_update_assignment(assignment, experiment)
      end

      project.user_group_assignments.find_each do |user_group_assignment|
        create_or_update_assignment(user_group_assignment, experiment)
      end

      project.team_assignments.find_each do |team_assignment|
        create_or_update_assignment(team_assignment, experiment)
      end
    end

    def assign_to_my_module(my_module)
      experiment = my_module.experiment
      experiment.user_assignments.find_each do |assignment|
        create_or_update_assignment(assignment, my_module)
      end

      experiment.user_group_assignments.find_each do |user_group_assignment|
        create_or_update_assignment(user_group_assignment, my_module)
      end

      experiment.team_assignments.find_each do |team_assignment|
        create_or_update_assignment(team_assignment, my_module)
      end
    end

    def assign_to_protocol(protocol)
      if protocol.parent_id && protocol.in_repository_draft?
        Protocol.transaction(requires_new: true) do
          protocol.parent.user_assignments.find_each do |assignment|
            protocol.parent.sync_child_protocol_assignment(assignment, protocol.id)
          end

          protocol.parent.user_group_assignments.find_each do |user_group_assignment|
            protocol.parent.sync_child_protocol_assignment(user_group_assignment, protocol.id)
          end

          protocol.parent.team_assignments.find_each do |team_assignment|
            protocol.parent.sync_child_protocol_assignment(team_assignment, protocol.id)
          end
        end

        return
      end

      return unless protocol.visible?

      protocol.create_or_update_team_assignment!(@assigned_by)
    end

    def assign_to_report(report)
      team = report.team
      team.user_assignments.find_each do |assignment|
        create_or_update_assignment(assignment, report)
      end
    end

    def create_or_update_assignment(parent_assignment, resource)
      type = parent_assignment.class.model_name.param_key.gsub('_assignment', '').to_sym

      new_assignment = parent_assignment.class.find_or_initialize_by(
        "#{type}_id": parent_assignment.public_send(type).id,
        assignable: resource,
        team_id: parent_assignment.team_id
      )

      return if new_assignment.manually_assigned?

      new_assignment.update!(
        user_role: parent_assignment.user_role,
        assigned_by: @assigned_by,
        assigned: :automatically
      )
    end
  end
end
