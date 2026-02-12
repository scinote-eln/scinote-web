# frozen_string_literal: true

module Api
  module V2
    class ExperimentUserGroupAssignmentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :check_read_permissions
      before_action :load_user_group_assignment, only: %i(show)
      before_action :load_user_group_assignment_for_managing, only: %i(update)

      def index
        user_group_assignments = timestamps_filter(@experiment.user_group_assignments).page(params.dig(:page, :number))
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

      def update
        @user_group_assignment.assign_attributes(user_group_assignment_params)
        return render body: nil, status: :no_content unless @user_group_assignment.changed?

        ActiveRecord::Base.transaction do
          @user_group_assignment.save!
          log_activity(:experiment_access_changed_user_group)
          propagate_job
        end

        render jsonapi: @user_group_assignment, serializer: UserGroupAssignmentSerializer, status: :ok
      end

      private

      def propagate_job
        UserAssignments::PropagateAssignmentJob.perform_later(@user_group_assignment)
      end

      def log_activity(type_of)
        Activities::CreateActivityService
          .call(activity_type: type_of,
                owner: current_user,
                subject: @experiment,
                team: @team,
                project: @project,
                message_items: { experiment: @experiment.id,
                                 user_group: @user_group_assignment.user_group.id,
                                 role: @user_group_assignment.user_role.name })
      end

      def check_read_permissions
        raise PermissionError.new(Experiment, :read_users) unless can_read_experiment_users?(@experiment)
      end

      def load_user_group_assignment
        @user_group_assignment = @experiment.user_group_assignments.find(params.require(:id))
      end

      def load_user_group_assignment_for_managing
        raise PermissionError.new(Project, :manage_users) unless can_manage_experiment_users?(@experiment)

        @user_group_assignment = @experiment.user_group_assignments.find(params.require(:id))
      end

      def user_group_assignment_params
        raise TypeError unless params.require(:data).require(:type) == 'user_group_assignments'

        params.require(:data).require(:attributes).permit(:user_group_id, :user_role_id)
      end
    end
  end
end
