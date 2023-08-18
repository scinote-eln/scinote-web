# frozen_string_literal: true

module Api
  module V1
    class InventoryStockUnitItemsController < BaseController
      before_action :load_team
      before_action :load_inventory
      before_action :load_inventory_column
      before_action :check_column_type
      before_action :load_inventory_stock_unit_item, only: %i(show update destroy)
      before_action :check_manage_permissions, only: %i(create update destroy)

      def index
        stock_unit_items =
          timestamps_filter(
            @inventory_column.repository_stock_unit_items
          )
          .page(params.dig(:page, :number))
          .per(params.dig(:page, :size))

        render jsonapi: stock_unit_items, each_serializer: InventoryStockUnitItemSerializer
      end

      def create
        stock_unit_item = @inventory_column.repository_stock_unit_items
                                           .create!(inventory_stock_unit_item_params)
        render jsonapi: stock_unit_item,
               serializer: InventoryStockUnitItemSerializer,
               status: :created
      end

      def show
        render jsonapi: @inventory_stock_unit_item,
               serializer: InventoryStockUnitItemSerializer
      end

      def update
        @inventory_stock_unit_item.attributes = update_inventory_stock_unit_item_params
        if @inventory_stock_unit_item.changed? && @inventory_stock_unit_item.save!
          render jsonapi: @inventory_stock_unit_item,
                          serializer: InventoryStockUnitItemSerializer
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @inventory_stock_unit_item.destroy!
        render body: nil
      end

      private

      def check_column_type
        raise TypeError unless @inventory_column.data_type == 'RepositoryStockValue'
      end

      def load_inventory_stock_unit_item
        @inventory_stock_unit_item =
          @inventory_column.repository_stock_unit_items.find(params.require(:id))
      end

      def check_manage_permissions
        raise PermissionError.new(RepositoryStockUnitItem, :manage) unless
          can_manage_repository_column?(@inventory_column)
      end

      def inventory_stock_unit_item_params
        raise TypeError unless params.require(:data).require(:type) == 'inventory_stock_unit_items'

        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(data) })[:data].merge(
          created_by: @current_user,
          last_modified_by: @current_user
        )
      end

      def update_inventory_stock_unit_item_params
        raise IDMismatchError unless params.require(:data).require(:id).to_i == params[:id].to_i

        inventory_stock_unit_item_params[:attributes]
      end
    end
  end
end
