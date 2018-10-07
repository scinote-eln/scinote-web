# frozen_string_literal: true

module Api
  module V1
    class TaskInventoryItemsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task
      before_action :load_inventory_item, only: :show

      def index
        items =
          @task.repository_rows
                    .includes(repository_cells: :repository_column)
                    .includes(
                      repository_cells: Extends::REPOSITORY_SEARCH_INCLUDES
                    ).page(params.dig(:page, :number))
                    .per(params.dig(:page, :size))
        incl = params[:include] == 'inventory_cells' ? :inventory_cells : nil
        render jsonapi: items,
               each_serializer: InventoryItemSerializer,
               show_repository: true,
               include: incl
      end

      def show
        render jsonapi: @item,
               serializer: InventoryItemSerializer,
               show_repository: true,
               include: %i(inventory_cells inventory)
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
        @task = @experiment.my_modules.find(params.require(:task_id))
        render jsonapi: {}, status: :not_found if @task.nil?
      end

      def load_inventory_item
        @item = @task.repository_rows.find(
          params.require(:id)
        )
        render jsonapi: {}, status: :not_found if @item.nil?
      end
    end
  end
end
