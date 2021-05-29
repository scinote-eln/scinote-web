# frozen_string_literal: true

module Api
  module V1
    class TaskUserAssignmentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task
      before_action :load_user_assignment, only: %i(update show destroy)
      before_action :load_user_assignment_for_managing, only: %i(update show destroy)

      def index
        user_assignments = @task.user_assignments
                                .includes(:user_role)
                                .page(params.dig(:page, :number))
                                .per(params.dig(:page, :size))

        render jsonapi: user_assignments,
               each_serializer: TaskUserAssignmentSerializer,
               include: %i(user user_role)
      end

      def show
        render jsonapi: @user_assignment,
               serializer: TaskUserAssignmentSerializer,
               include: %i(user user_role)
      end

      def create
        raise PermissionError.new(MyModule, :read) unless can_manage_module?(@task)

        my_module_member = MyModuleMember.new(current_user, @task, @experiment, @project)
        my_module_member.create(
          user_role_id: user_assignment_params[:user_role_id],
          user_id: user_assignment_params[:user_id]
        )

        render jsonapi: my_module_member.user_assignment.reload,
               serializer: TaskUserAssignmentSerializer,
               status: :created
      end

      def update
        user_role = UserRole.find user_assignment_params[:user_role_id]
        user = @user_assignment.user
        my_module_member = MyModuleMember.new(
          current_user,
          @task,
          @experiment,
          @project,
          user,
          @user_assignment
        )

        return render body: nil, status: :no_content if @user_assignment.user_role == user_role

        my_module_member.update(user_role_id: user_role.id, user_id: user.id)

        render jsonapi: my_module_member.user_assignment.reload,
               serializer: TaskUserAssignmentSerializer,
               status: :ok
      end

      def destroy
        my_module_member = MyModuleMember.new(
          current_user,
          @task,
          @experiment,
          @project,
          @user_assignment.user,
          @user_assignment
        )
        my_module_member.destroy
        render body: nil
      end

      private

      def load_user_assignment
        @user_assignment = @task.user_assignments.find(params.require(:id))
      end

      def load_user_assignment_for_managing
        raise PermissionError.new(MyModule, :manage) unless can_manage_module?(@task)
      end

      def user_assignment_params
        raise TypeError unless params.require(:data).require(:type) == 'task_user_assignments'

        params.require(:data).require(:attributes).permit(:user_id, :user_role_id)
      end
    end
  end
end
