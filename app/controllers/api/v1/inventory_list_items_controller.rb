# frozen_string_literal: true

module Api
  module V1
    class InventoryListItemsController < BaseController
      before_action :load_team
      before_action :load_inventory
      before_action :load_inventory_column
      before_action :check_column_type
      before_action :load_inventory_list_item, only: %i(show update destroy)
      before_action :check_manage_permissions, only: %i(create update destroy)

      def index
        list_items = @inventory_column.repository_list_items
                                      .page(params.dig(:page, :number))
                                      .per(params.dig(:page, :size))
        render jsonapi: list_items, each_serializer: InventoryListItemSerializer
      end

      def create
        list_item = @inventory_column.repository_list_items
                                     .create!(inventory_list_item_params)
        render jsonapi: list_item,
               serializer: InventoryListItemSerializer,
               status: :created
      end

      def show
        render jsonapi: @inventory_list_item,
               serializer: InventoryListItemSerializer
      end

      def update
        @inventory_list_item.attributes = update_inventory_list_item_params
        if @inventory_list_item.changed? && @inventory_list_item.save!
          render jsonapi: @inventory_list_item,
                          serializer: InventoryListItemSerializer
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @inventory_list_item.destroy!
        render body: nil
      end

      private

      def check_column_type
        unless @inventory_column.data_type == 'RepositoryListValue'
          raise TypeError
        end
      end

      def load_inventory_list_item
        @inventory_list_item =
          @inventory_column.repository_list_items.find(params.require(:id))
      end

      def check_manage_permissions
        unless can_manage_repository_column?(@inventory_column)
          raise PermissionError.new(RepositoryListItem, :manage)
        end
      end

      def inventory_list_item_params
        unless params.require(:data).require(:type) == 'inventory_list_items'
          raise TypeError
        end
        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(data) })[:data].merge(
          created_by: @current_user,
          last_modified_by: @current_user,
          repository: @inventory
        )
      end

      def update_inventory_list_item_params
        unless params.require(:data).require(:id).to_i == params[:id].to_i
          raise IDMismatchError
        end
        inventory_list_item_params[:attributes]
      end
    end
  end
end
