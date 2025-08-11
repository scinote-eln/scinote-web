# frozen_string_literal: true

module Api
  module V1
    class TaskInventoryItemsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task
      before_action :load_inventory_item, only: %i(show destroy update)
      before_action :load_task_inventory_item, only: %i(update destroy)
      before_action :check_repository_view_permissions, only: :show
      before_action :check_stock_consumption_update_permissions, only: :update
      before_action :check_task_assign_permissions, only: %i(create destroy)

      def index
        items = @task.repository_rows.where(repository_id: Repository.readable_by_user(current_user).select(:id))
        items = timestamps_filter(items).includes(repository_cells: :repository_column)
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
        render jsonapi: @inventory_item,
               serializer: TaskInventoryItemSerializer,
               show_repository: true,
               my_module: @task,
               include: %i(inventory_cells inventory)
      end

      def create
        @inventory_item = RepositoryRow.find_by(id: repository_row_params[:attributes][:item_id])

        raise PermissionError.new(Repository, :read) unless @inventory_item && can_read_repository?(@inventory_item.repository)

        @task.my_module_repository_rows.create!(repository_row: @inventory_item, assigned_by: current_user)

        render jsonapi: @inventory_item,
               serializer: TaskInventoryItemSerializer,
               show_repository: true,
               my_module: @task,
               include: include_params
      end

      def update
        @task_inventory_item.consume_stock(
          current_user,
          repository_row_params[:attributes][:stock_consumption],
          repository_row_params[:attributes][:stock_consumption_comment]
        )

        render jsonapi: @inventory_item,
               serializer: TaskInventoryItemSerializer,
               show_repository: true,
               my_module: @task,
               include: %i(inventory_cells inventory)
      end

      def destroy
        @task_inventory_item.destroy!

        render body: nil
      end

      private

      def load_inventory_item
        @inventory_item = @task.repository_rows.find(params.require(:id))
      end

      def load_task_inventory_item
        @task_inventory_item = @task.my_module_repository_rows.find_by!(repository_row: @inventory_item)
      end

      def check_repository_view_permissions
        raise PermissionError.new(RepositoryRow, :read_repository) unless can_read_repository?(@inventory_item.repository)
      end

      def check_stock_consumption_update_permissions
        raise PermissionError.new(RepositoryRow, :update_stock_consumption) if @inventory_item.archived? || !can_update_my_module_stock_consumption?(@task)
      end

      def check_task_assign_permissions
        raise PermissionError.new(MyModule, :assing_repository_item_to_task) unless can_assign_my_module_repository_rows?(@task)
      end

      def repository_row_params
        raise TypeError unless params.require(:data).require(:type) == 'inventory_items'

        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(stock_consumption stock_consumption_comment item_id) })[:data]
      end

      def permitted_includes
        %w(inventory_cells)
      end
    end
  end
end
