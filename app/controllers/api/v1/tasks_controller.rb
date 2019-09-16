# frozen_string_literal: true

module Api
  module V1
    class TasksController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action only: :show do
        load_task(:id)
      end
      before_action :load_task_relative, only: :activities

      def index
        tasks = @experiment.my_modules
                           .page(params.dig(:page, :number))
                           .per(params.dig(:page, :size))

        render jsonapi: tasks, each_serializer: TaskSerializer
      end

      def show
        render jsonapi: @task, serializer: TaskSerializer
      end

      def create
        raise PermissionError.new(MyModule, :create) unless can_manage_experiment?(@experiment)

        my_module = @experiment.my_modules.create!(my_module_params)

        render jsonapi: my_module,
               serializer: TaskSerializer,
               status: :created
      end

      def activities
        activities = ActivitiesService.my_module_activities(@task)
                                      .page(params.dig(:page, :number))
                                      .per(params.dig(:page, :size))

        render jsonapi: activities,
          each_serializer: ActivitySerializer
      end

      private

      def my_module_params
        raise TypeError unless params.require(:data).require(:type) == 'tasks'

        attr_list = %i(name x y)
        params.require(:data).require(:attributes).require(attr_list)
        params.require(:data).require(:attributes).permit(attr_list + [:description])
      end

      # Made the method below because its more elegant than changing parameters
      # in routes file, and here. It exists because when we call input or output
      # for a task, the "id" that used to be task id is now an id for the output
      # or input.
      def load_task_relative
        @task = @experiment.my_modules.find(params.require(:task_id))
      end
    end
  end
end
