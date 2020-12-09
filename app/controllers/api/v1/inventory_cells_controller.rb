# frozen_string_literal: true

module Api
  module V1
    class InventoryCellsController < BaseController
      before_action :load_team
      before_action :load_inventory
      before_action :load_inventory_column, only: :create
      before_action :load_inventory_item
      before_action :load_inventory_cell, only: %i(show update destroy)
      before_action :check_manage_permissions, only: %i(create update destroy)

      def index
        cells = @inventory_item.repository_cells
                               .preload(@inventory.cell_preload_includes)
                               .page(params.dig(:page, :number))
                               .per(params.dig(:page, :size))
        render jsonapi: cells, each_serializer: InventoryCellSerializer
      end

      def create
        cell = RepositoryCell.create_with_value!(@inventory_item,
                                                 @inventory_column,
                                                 inventory_cell_params[:value],
                                                 current_user)
        render jsonapi: cell,
               serializer: InventoryCellSerializer,
               status: :created
      end

      def show
        render jsonapi: @inventory_cell, serializer: InventoryCellSerializer
      end

      def update
        value = update_inventory_cell_params[:value]
        if @inventory_cell.value.data_changed?(value)
          @inventory_cell.value.update_data!(value, current_user)
          render jsonapi: @inventory_cell, serializer: InventoryCellSerializer
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @inventory_cell.destroy!
        render body: nil
      end

      private

      def load_inventory_column
        @inventory_column = @inventory.repository_columns
                                      .find(inventory_cell_params[:column_id])
      end

      def load_inventory_cell
        @inventory_cell = @inventory_item.repository_cells
                                         .find(params[:id].to_i)
      end

      def check_manage_permissions
        raise PermissionError.new(RepositoryRow, :manage) unless can_manage_repository_rows?(@inventory)
      end

      def inventory_cell_params
        unless params.require(:data).require(:type) == 'inventory_cells'
          raise TypeError
        end
        params.require(:data).require(:attributes).require(:column_id)
        params.require(:data).require(:attributes).require(:value)
        params[:data][:attributes]
      end

      def update_inventory_cell_params
        unless params.require(:data).require(:id).to_i == params[:id].to_i
          raise IDMismatchError
        end
        inventory_cell_params
      end
    end
  end
end
