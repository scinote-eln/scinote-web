# frozen_string_literal: true

module Api
  module V1
    class TaskInventoryItemsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task
      before_action :load_my_module_repository_row, only: :update
      before_action :check_stock_consumption_update_permissions, only: :update

      def index
        items =
          timestamps_filter(@task.repository_rows).includes(repository_cells: :repository_column)
                                                  .preload(repository_cells: :value)
                                                  .page(params.dig(:page, :number))
                                                  .per(params.dig(:page, :size))
        render jsonapi: items,
               each_serializer: TaskInventoryItemSerializer,
               show_repository: true,
               my_module: @task,
               include: include_params
      end

      def show
        render jsonapi: @task.repository_rows.find(params.require(:id)),
               serializer: TaskInventoryItemSerializer,
               show_repository: true,
               my_module: @task,
               include: %i(inventory_cells inventory)
      end

      def update
        @my_module_repository_row.consume_stock(
          current_user,
          repository_row_params[:attributes][:stock_consumption],
          repository_row_params[:attributes][:stock_consumption_comment]
        )

        render jsonapi: @my_module_repository_row.repository_row,
               serializer: TaskInventoryItemSerializer,
               show_repository: true,
               my_module: @task,
               include: %i(inventory_cells inventory)
      end

      private

      def load_my_module_repository_row
        @my_module_repository_row = @task.repository_rows
                                         .find(params.require(:id))
                                         .my_module_repository_rows
                                         .find_by(my_module: @task)
      end

      def check_stock_consumption_update_permissions
        unless can_update_my_module_stock_consumption?(@task) &&
               can_manage_repository_rows?(@my_module_repository_row.repository_row.repository)
          raise PermissionError.new(RepositoryRow, :update_stock_consumption)
        end
      end

      def repository_row_params
        raise TypeError unless params.require(:data).require(:type) == 'inventory_items'

        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(stock_consumption stock_consumption_comment) })[:data]
      end

      def permitted_includes
        %w(inventory_cells)
      end
    end
  end
end
