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
      before_action :load_task_relative, only: %i(inputs outputs activities)

      def index
        tasks = @experiment.my_modules
                           .page(params.dig(:page, :number))
                           .per(params.dig(:page, :size))

        render jsonapi: tasks, each_serializer: TaskSerializer
      end

      def show
        render jsonapi: @task, serializer: TaskSerializer
      end

      def inputs
        inputs = @task.my_module_antecessors
                      .page(params.dig(:page, :number))
                      .per(params.dig(:page, :size))
        render jsonapi: inputs, each_serializer: TaskSerializer
      end

      def outputs
        outputs = @task.my_modules
                       .page(params.dig(:page, :number))
                       .per(params.dig(:page, :size))
        render jsonapi: outputs, each_serializer: TaskSerializer
      end

      def activities
        activities = @task.activities
                          .page(params.dig(:page, :number))
                          .per(params.dig(:page, :size))

        render jsonapi: activities,
          each_serializer: ActivitySerializer
      end

      private

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
