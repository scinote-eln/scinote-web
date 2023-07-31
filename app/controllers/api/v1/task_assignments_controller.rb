# frozen_string_literal: true

module Api
  module V1
    class TaskAssignmentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task
      before_action :check_manage_permissions, only: %i(create destroy)

      def index
        users = timestamps_filter(User).joins(:user_my_modules)
                                       .where(user_my_modules: { my_module_id: @task.id })
                                       .page(params.dig(:page, :number))
                                       .per(params.dig(:page, :size))
        render jsonapi: users, each_serializer: UserSerializer
      end

      def create
        user = User.find task_assignment_params[:user_id]
        um = UserMyModule.new(my_module: @task, user: user)
        um.assigned_by = current_user
        um.log_activity(:designate_user_to_my_module, um.assigned_by) if um.save!

        render jsonapi: um, serializer: TaskAssignmentSerializer
      end

      def destroy
        um = @task.user_my_modules.find_by!(user_id: params.require(:id))
        um.log_activity(:undesignate_user_from_my_module, current_user) if um.destroy
        render body: nil
      end

      private

      def task_assignment_params
        raise TypeError unless params.require(:data).require(:type) == 'task_assignments'

        params.require(:data).require(:attributes).permit(:user_id)
      end

      def check_manage_permissions
        raise PermissionError.new(MyModule, :manage) unless can_manage_my_module?(@task)
      end
    end
  end
end
