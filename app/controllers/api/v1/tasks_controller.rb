# frozen_string_literal: true

module Api
  module V1
    class TasksController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task, only: :show
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

      def load_team
        @team = Team.find(params.require(:team_id))
        render jsonapi: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_project
        @project = @team.projects.find(params.require(:project_id))
        render jsonapi: {}, status: :forbidden unless can_read_project?(
          @project
        )
      end

      def load_experiment
        @experiment = @project.experiments.find(params.require(:experiment_id))
        render jsonapi: {}, status: :forbidden unless can_read_experiment?(
          @experiment
        )
      end

      def load_task
        @task = @experiment.my_modules.find(params.require(:id))
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
