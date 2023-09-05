# frozen_string_literal: true

module Api
  module V1
    class TaskUserAssignmentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task
      before_action :check_read_permissions
      before_action :load_user_assignment, only: %i(update show)
      before_action :load_user_assignment_for_managing, only: %i(update show)

      def index
        user_assignments = timestamps_filter(@task.user_assignments).includes(:user_role)
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
        ActiveRecord::Base.transaction do
          if @user_assignment.user_role_id == user_assignment_params[:user_role_id]
            return render body: nil, status: :no_content
          end

          @user_assignment.update!(user_assignment_params.merge(assigned: :manually))
          log_change_activity

          render jsonapi: @user_assignment.reload,
                 serializer: UserAssignmentSerializer,
                 status: :ok
        end
      end

      private

      def check_read_permissions
        raise PermissionError.new(MyModule, :read_users) unless can_read_my_module_users?(@task)
      end

      def load_user_assignment
        @user_assignment = @task.user_assignments.find(params.require(:id))
      end

      def load_user_assignment_for_managing
        raise PermissionError.new(MyModule, :manage_users) unless can_manage_my_module_users?(@task)
      end

      def user_assignment_params
        raise TypeError unless params.require(:data).require(:type) == 'user_assignments'

        params.require(:data).require(:attributes).permit(:user_id, :user_role_id)
      end

      def permitted_includes
        %w(user user_role assignable)
      end

      def log_change_activity
        Activities::CreateActivityService.call(
          activity_type: :change_user_role_on_my_module,
          owner: current_user,
          subject: @task,
          team: @project.team,
          project: @project,
          message_items: {
            my_module: @task.id,
            user_target: @user_assignment.user_id,
            role: @user_assignment.user_role.name
          }
        )
      end
    end
  end
end
