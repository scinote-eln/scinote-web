# frozen_string_literal: true

module Api
  module V1
    class InventoryStatusItemsController < BaseController
      before_action :load_team, :load_inventory, :load_inventory_column, :check_column_type
      before_action :load_inventory_status_item, only: %i(show update destroy)
      before_action :check_manage_permissions, only: %i(create update destroy)

      def index
        status_items = @inventory_column.repository_status_items
                                        .page(params.dig(:page, :number))
                                        .per(params.dig(:page, :size))
        render jsonapi: status_items, each_serializer: InventoryStatusItemSerializer
      end

      def create
        status_item = @inventory_column.repository_status_items.create!(inventory_status_item_params)
        render jsonapi: status_item,
               serializer: InventoryStatusItemSerializer,
               status: :created
      end

      def show
        render jsonapi: @inventory_status_item,
               serializer: InventoryStatusItemSerializer
      end

      def update
        @inventory_status_item.attributes = update_inventory_status_item_params
        if @inventory_status_item.changed? && @inventory_status_item.save!
          render jsonapi: @inventory_status_item,
                 serializer: InventoryStatusItemSerializer
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @inventory_status_item.destroy!
        render body: nil, status: :ok
      end

      private

      def check_column_type
        raise TypeError unless @inventory_column.data_type == 'RepositoryStatusValue'
      end

      def load_inventory_status_item
        @inventory_status_item = @inventory_column.repository_status_items.find(params.require(:id))
      end

      def check_manage_permissions
        raise PermissionError.new(RepositoryStatusItem, :manage) unless can_manage_repository_column?(@inventory_column)
      end

      def inventory_status_item_params
        raise TypeError unless params.require(:data).require(:type) == 'inventory_status_items'

        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(status icon) })[:data].merge(
          created_by: @current_user,
          last_modified_by: @current_user,
          repository: @inventory
        )
      end

      def update_inventory_status_item_params
        raise IDMismatchError unless params.require(:data).require(:id).to_i == params[:id].to_i

        inventory_status_item_params[:attributes]
      end
    end
  end
end
