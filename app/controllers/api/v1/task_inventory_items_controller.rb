# frozen_string_literal: true

module Api
  module V1
    class TaskInventoryItemsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task

      def index
        items =
          @task.repository_rows
               .includes(repository_cells: :repository_column)
               .includes(repository_cells: Extends::REPOSITORY_SEARCH_INCLUDES)
               .page(params.dig(:page, :number))
               .per(params.dig(:page, :size))
        incl = params[:include] == 'inventory_cells' ? :inventory_cells : nil
        render jsonapi: items,
               each_serializer: InventoryItemSerializer,
               show_repository: true,
               include: incl
      end

      def show
        render jsonapi: @task.repository_rows.find(params.require(:id)),
               serializer: InventoryItemSerializer,
               show_repository: true,
               include: %i(inventory_cells inventory)
      end
    end
  end
end
