# frozen_string_literal: true

module Api
  module V1
    class TaskGroupsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task_group, only: :show

      def index
        my_module_groups = @experiment.my_module_groups
                                      .page(params.dig(:page, :number))
                                      .per(params.dig(:page, :size))
        incl = params[:include] == 'tasks' ? :tasks : nil
        render jsonapi: my_module_groups,
               each_serializer: TaskGroupSerializer,
               include: incl
      end

      def show
        render jsonapi: @my_module_group,
               serializer: TaskGroupSerializer,
               include: :tasks
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

      def load_task_group
        @my_module_group = @experiment.my_module_groups.find(
          params.require(:id)
        )
      end
    end
  end
end
