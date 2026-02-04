# frozen_string_literal: true

module Api
  module V2
    class ProjectUserGroupAssignmentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :check_read_permissions
      before_action :load_user_group_assignment, only: %i(show)
      before_action :load_user_group_assignment_for_managing, only: %i(update destroy)

      def index
        user_group_assignments = timestamps_filter(@project.user_group_assignments).page(params.dig(:page, :number))
                                                                                   .per(params.dig(:page, :size))
        render jsonapi: user_group_assignments,
               each_serializer: UserGroupAssignmentSerializer,
               include: include_params
      end

      def show
        render jsonapi: @user_group_assignment,
               serializer: UserGroupAssignmentSerializer,
               include: include_params
      end

      def create
        raise PermissionError.new(Project, :manage) unless can_manage_project_users?(@project)

        ActiveRecord::Base.transaction do
          @user_group_assignment = @project.user_group_assignments.create!(
            user_group_id: user_group_assignment_params[:user_group_id],
            user_role_id: user_group_assignment_params[:user_role_id],
            team: @team,
            assigned_by: current_user,
            assigned: :manually
          )
          log_activity(:project_access_granted_user_group)
          propagate_job
        end

        render jsonapi: @user_group_assignment,
               serializer: UserGroupAssignmentSerializer,
               status: :created
      end

      def update
        @user_group_assignment.assign_attributes(user_group_assignment_params)
        return render body: nil, status: :no_content unless @user_group_assignment.changed?

        ActiveRecord::Base.transaction do
          @user_group_assignment.save!
          log_activity(:project_access_changed_user_group)
          propagate_job
        end

        render jsonapi: @user_group_assignment, serializer: UserGroupAssignmentSerializer, status: :ok
      end

      def destroy
        ActiveRecord::Base.transaction do
          @user_group_assignment.destroy!
          propagate_job(destroy: true)
          log_activity(:project_access_revoked_user_group)
        end

        render body: nil
      end

      private

      def propagate_job(destroy: false)
        UserAssignments::PropagateAssignmentJob.perform_later(
          @user_group_assignment,
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
                                 user_group: @user_group_assignment.user_group.id,
                                 role: @user_group_assignment.user_role.name })
      end

      # Override, in order to handle special case for team owners
      def load_project
        @project = @team.projects.find(params.require(:project_id))
      end

      def check_read_permissions
        raise PermissionError.new(Project, :read_users) unless can_read_project_users?(@project)
      end

      def load_user_group_assignment
        @user_group_assignment = @project.user_group_assignments.find(params.require(:id))
      end

      def load_user_group_assignment_for_managing
        raise PermissionError.new(Project, :manage_users) unless can_manage_project_users?(@project)

        @user_group_assignment = @project.user_group_assignments.find(params.require(:id))
      end

      def user_group_assignment_params
        raise TypeError unless params.require(:data).require(:type) == 'user_group_assignments'

        params.require(:data).require(:attributes).permit(:user_group_id, :user_role_id)
      end
    end
  end
end
