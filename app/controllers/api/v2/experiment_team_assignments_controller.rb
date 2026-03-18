# frozen_string_literal: true

module Api
  module V2
    class ExperimentTeamAssignmentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :check_read_permissions
      before_action :load_team_assignment, only: %i(show)
      before_action :load_team_assignment_for_managing, only: %i(update)

      def index
        team_assignments = timestamps_filter(@experiment.team_assignments).page(params.dig(:page, :number))
                                                                          .per(params.dig(:page, :size))
        render jsonapi: team_assignments,
               each_serializer: TeamAssignmentSerializer,
               include: include_params
      end

      def show
        render jsonapi: @team_assignment,
               serializer: TeamAssignmentSerializer,
               include: include_params
      end

      def update
        @team_assignment.assign_attributes(team_assignment_params)
        return render body: nil, status: :no_content unless @team_assignment.changed?

        ActiveRecord::Base.transaction do
          @team_assignment.save!
          log_activity(:experiment_access_changed_all_team_members)
          propagate_job
        end

        render jsonapi: @team_assignment, serializer: TeamAssignmentSerializer, status: :ok
      end

      private

      def propagate_job
        UserAssignments::PropagateAssignmentJob.perform_later(@team_assignment, assigner_id: current_user.id)
      end

      def log_activity(type_of)
        Activities::CreateActivityService
          .call(activity_type: type_of,
                owner: current_user,
                subject: @experiment,
                team: @team,
                project: @project,
                message_items: { experiment: @experiment.id,
                                 team: @team.id,
                                 role: @team_assignment.user_role.name })
      end

      def check_read_permissions
        raise PermissionError.new(Experiment, :read_users) unless can_read_experiment_users?(@experiment)
      end

      def load_team_assignment
        @team_assignment = @experiment.team_assignments.find(params.require(:id))
      end

      def load_team_assignment_for_managing
        raise PermissionError.new(Project, :manage_users) unless can_manage_experiment_users?(@experiment)

        @team_assignment = @experiment.team_assignments.find(params.require(:id))
      end

      def team_assignment_params
        raise TypeError unless params.require(:data).require(:type) == 'team_assignments'

        params.require(:data).require(:attributes).permit(:user_role_id)
      end
    end
  end
end
