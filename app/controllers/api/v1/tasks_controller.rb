# frozen_string_literal: true

module Api
  module V1
    class TasksController < BaseController
      include Api::V1::ExtraParams

      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action only: :show do
        load_task(:id)
      end
      before_action :load_task_for_managing, only: %i(update)
      before_action :load_task, only: :activities

      def index
        tasks = @experiment.my_modules
                           .includes(:my_module_status, :my_modules, :my_module_antecessors)
                           .page(params.dig(:page, :number))
                           .per(params.dig(:page, :size))

        render jsonapi: tasks, each_serializer: TaskSerializer,
                               include: include_params,
                               rte_rendering: render_rte?,
                               team: @team
      end

      def show
        render jsonapi: @task, serializer: TaskSerializer,
                               include: include_params,
                               rte_rendering: render_rte?,
                               team: @team
      end

      def create
        raise PermissionError.new(MyModule, :create) unless can_manage_experiment?(@experiment)

        my_module = @experiment.my_modules.create!(task_params_create)

        render jsonapi: my_module, serializer: TaskSerializer,
                                   rte_rendering: render_rte?,
                                   status: :created
      end

      def update
        @task.assign_attributes(task_params_update)

        if @task.changed? && @task.save!
          render jsonapi: @task, serializer: TaskSerializer, status: :ok
        else
          render body: nil, status: :no_content
        end
      end

      def activities
        activities = ActivitiesService.my_module_activities(@task)
                                      .page(params.dig(:page, :number))
                                      .per(params.dig(:page, :size))

        render jsonapi: activities, each_serializer: ActivitySerializer
      end

      private

      def task_params_create
        raise TypeError unless params.require(:data).require(:type) == 'tasks'

        params.require(:data).require(:attributes).permit(%i(name x y description))
      end

      def task_params_update
        raise TypeError unless params.require(:data).require(:type) == 'tasks'

        params.require(:data).require(:attributes).permit(%i(name x y description my_module_status_id))
      end

      def permitted_includes
        %w(comments)
      end

      def load_task_for_managing
        @task = @experiment.my_modules.find(params.require(:id))
        raise PermissionError.new(MyModule, :manage) unless can_manage_module?(@task)
      end
    end
  end
end
