# frozen_string_literal: true

module Api
  module V1
    class ExperimentUserAssignmentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :check_read_permissions
      before_action :load_user_assignment, only: %i(update show)
      before_action :load_user_assignment_for_managing, only: %i(update show)

      def index
        user_assignments = @experiment.user_assignments
                                      .includes(:user_role)
                                      .page(params.dig(:page, :number))
                                      .per(params.dig(:page, :size))

        render jsonapi: user_assignments,
               each_serializer: UserAssignmentSerializer,
               include: include_params
      end

      def show
        render jsonapi: @user_assignment,
               serializer: UserAssignmentSerializer,
               include: include_params
      end

      def update
        user_role = UserRole.find user_assignment_params[:user_role_id]
        user = @user_assignment.user
        experiment_member = ExperimentMember.new(
          current_user,
          @experiment,
          @project,
          user,
          @user_assignment
        )

        return render body: nil, status: :no_content if @user_assignment.user_role == user_role

        experiment_member.update(user_role_id: user_role.id, user_id: user.id)
        render jsonapi: experiment_member.user_assignment.reload,
               serializer: UserAssignmentSerializer,
               status: :ok
      end

      private

      def check_read_permissions
        raise PermissionError.new(Experiment, :read_users) unless can_read_experiment_users?(@experiment)
      end

      def load_user_assignment
        @user_assignment = @experiment.user_assignments.find(params.require(:id))
      end

      def load_user_assignment_for_managing
        raise PermissionError.new(Experiment, :manage_users) unless can_manage_experiment_users?(@experiment)
      end

      def user_assignment_params
        raise TypeError unless params.require(:data).require(:type) == 'user_assignments'

        params.require(:data).require(:attributes).permit(:user_id, :user_role_id)
      end

      def permitted_includes
        %w(user user_role assignable)
      end
    end
  end
end
