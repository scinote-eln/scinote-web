# frozen_string_literal: true

module Api
  module V1
    class TaskGroupsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task_group, only: :show

      def index
        task_groups = @experiment.my_module_groups
                                 .page(params.dig(:page, :number))
                                 .per(params.dig(:page, :size))
        incl = params[:include] == 'tasks' ? :tasks : nil
        render jsonapi: task_groups,
               each_serializer: TaskGroupSerializer,
               include: incl
      end

      def show
        render jsonapi: @task_group,
               serializer: TaskGroupSerializer,
               include: :tasks
      end

      private

      def load_task_group
        @task_group = @experiment.my_module_groups.find(params.require(:id))
      end
    end
  end
end
