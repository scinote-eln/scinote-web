# frozen_string_literal: true

module Api
  module V1
    class InventoryChecklistItemsController < BaseController
      before_action :load_team
      before_action :load_inventory
      before_action :load_inventory_column
      before_action :check_column_type
      before_action :load_inventory_checklist_item, only: %i(show update destroy)
      before_action :check_manage_permissions, only: %i(create update destroy)

      def index
        checklist_items =
          timestamps_filter(@inventory_column.repository_checklist_items).page(params.dig(:page, :number))
                                                                         .per(params.dig(:page, :size))

        render jsonapi: checklist_items, each_serializer: InventoryChecklistItemSerializer
      end

      def create
        checklist_item = @inventory_column.repository_checklist_items
                                          .create!(inventory_checklist_item_params)
        render jsonapi: checklist_item,
               serializer: InventoryChecklistItemSerializer,
               status: :created
      end

      def show
        render jsonapi: @inventory_checklist_item,
               serializer: InventoryChecklistItemSerializer
      end

      def update
        @inventory_checklist_item.attributes = update_inventory_checklist_item_params
        if @inventory_checklist_item.changed? && @inventory_checklist_item.save!
          render jsonapi: @inventory_checklist_item,
                          serializer: InventoryChecklistItemSerializer
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @inventory_checklist_item.destroy!
        render body: nil
      end

      private

      def check_column_type
        raise TypeError unless @inventory_column.data_type == 'RepositoryChecklistValue'
      end

      def load_inventory_checklist_item
        @inventory_checklist_item = @inventory_column.repository_checklist_items.find(params.require(:id))
      end

      def check_manage_permissions
        unless can_manage_repository_column?(@inventory_column)
          raise PermissionError.new(RepositoryChecklistItem, :manage)
        end
      end

      def inventory_checklist_item_params
        raise TypeError unless params.require(:data).require(:type) == 'inventory_checklist_items'

        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(data) })[:data].merge(
          created_by: @current_user,
          last_modified_by: @current_user
        )
      end

      def update_inventory_checklist_item_params
        raise IDMismatchError unless params.require(:data).require(:id).to_i == params[:id].to_i

        inventory_checklist_item_params[:attributes]
      end
    end
  end
end
