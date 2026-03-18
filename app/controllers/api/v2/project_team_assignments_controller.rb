# frozen_string_literal: true

module Api
  module V2
    class ProjectTeamAssignmentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :check_read_permissions
      before_action :load_team_assignment, only: %i(show)
      before_action :load_team_assignment_for_managing, only: %i(update destroy)

      def index
        team_assignments = timestamps_filter(@project.team_assignments).page(params.dig(:page, :number))
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

      def create
        raise PermissionError.new(Project, :manage) unless can_manage_project_users?(@project)

        ActiveRecord::Base.transaction do
          @team_assignment = @project.team_assignments.create!(
            team: @team,
            user_role_id: team_assignment_params[:user_role_id],
            assigned_by: current_user,
            assigned: :manually
          )
          log_activity(:project_grant_access_to_all_team_members)
          propagate_job
        end

        render jsonapi: @team_assignment,
               serializer: TeamAssignmentSerializer,
               status: :created
      end

      def update
        @team_assignment.assign_attributes(team_assignment_params)
        return render body: nil, status: :no_content unless @team_assignment.changed?

        ActiveRecord::Base.transaction do
          @team_assignment.save!
          log_activity(:project_access_changed_all_team_members)
          propagate_job
        end

        render jsonapi: @team_assignment, serializer: TeamAssignmentSerializer, status: :ok
      end

      def destroy
        ActiveRecord::Base.transaction do
          @team_assignment.destroy!
          propagate_job(destroy: true)
          log_activity(:project_remove_access_from_all_team_members)
        end

        render body: nil
      end

      private

      def propagate_job(destroy: false)
        UserAssignments::PropagateAssignmentJob.perform_later(
          @team_assignment,
          assigner_id: current_user.id,
          destroy: destroy
        )
      end

      def log_activity(type_of)
        Activities::CreateActivityService
          .call(activity_type: type_of,
                owner: current_user,
                subject: @project,
                team: @team,
                project: @project,
                message_items: { project: @project.id,
                                 team: @team.id,
                                 role: @team_assignment.user_role.name })
      end

      # Override, in order to handle special case for team owners
      def load_project
        @project = @team.projects.find(params.require(:project_id))
      end

      def check_read_permissions
        raise PermissionError.new(Project, :read_users) unless can_read_project_users?(@project)
      end

      def load_team_assignment
        @team_assignment = @project.team_assignments.find(params.require(:id))
      end

      def load_team_assignment_for_managing
        raise PermissionError.new(Project, :manage_users) unless can_manage_project_users?(@project)

        @team_assignment = @project.team_assignments.find(params.require(:id))
      end

      def team_assignment_params
        raise TypeError unless params.require(:data).require(:type) == 'team_assignments'

        params.require(:data).require(:attributes).permit(:user_role_id)
      end
    end
  end
end
