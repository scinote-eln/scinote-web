# frozen_string_literal: true

module Api
  module V1
    class ExperimentUserAssignmentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_user_assignment, only: :show
      before_action :load_user_assignment_for_managing, only: %i(update destroy)

      def index
        user_assignments = @experiment.user_assignments
                                      .includes(:user_role)
                                      .page(params.dig(:page, :number))
                                      .per(params.dig(:page, :size))

        render jsonapi: user_assignments,
               each_serializer: ExperimentUserAssignmentSerializer,
               include: :user
      end

      def show
        render jsonapi: @user_assignment,
               serializer: ExperimentUserAssignmentSerializer,
               include: :user
      end

      def create
        raise PermissionError.new(Experiment, :manage) unless can_manage_experiment?(@experiment)

        user_role = UserRole.find_by_name incoming_role_name(user_assignment_params[:role])
        experiment_member = ExperimentMember.new(current_user, @experiment, @project)
        experiment_member.create(
          user_role_id: user_role.id,
          user_id: user_assignment_params[:user_id]
        )

        render jsonapi: experiment_member.user_assignment.reload, serializer: ExperimentUserAssignmentSerializer, status: :created
      end

      def update
        user_role = UserRole.find_by_name incoming_role_name(user_assignment_params[:role])
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
        render jsonapi: experiment_member.user_assignment.reload, serializer: ExperimentUserAssignmentSerializer, status: :ok
      end

      def destroy
        experiment_member = ExperimentMember.new(
          current_user,
          @experiment,
          @project,
          @user_assignment.user,
          @user_assignment
        )
        experiment_member.destroy
        render body: nil
      end

      private

      include Api::V1::UserRoleSanitizer

      def load_user_assignment
        @user_assignment = @experiment.user_assignments.find(params.require(:id))
      end

      def load_user_assignment_for_managing
        @user_assignment = @experiment.user_assignments.find(params.require(:id))
        raise PermissionError.new(Experiment, :manage) unless can_manage_experiment?(@experiment)
      end

      def user_assignment_params
        raise TypeError unless params.require(:data).require(:type) == 'experiment_user_assignments'

        params.require(:data).require(:attributes).permit(:user_id, :role)
      end
    end
  end
end
