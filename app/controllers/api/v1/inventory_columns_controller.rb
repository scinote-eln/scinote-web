# frozen_string_literal: true

module Api
  module V1
    class InventoryColumnsController < BaseController
      before_action :load_team
      before_action :load_inventory
      before_action :load_inventory_column, only: %i(show update destroy)
      before_action :check_manage_permissions, only: %i(create update destroy)

      def index
        columns = @inventory.repository_columns
                            .includes(:repository_list_items)
                            .page(params.dig(:page, :number))
                            .per(params.dig(:page, :size))
        render jsonapi: columns, each_serializer: InventoryColumnSerializer,
        include: :inventory_list_items
      end

      def create
        inventory_column =
          @inventory.inventory_columns.create!(inventory_column_params)
        render jsonapi: inventory_column,
               serializer: InventoryColumnSerializer,
               status: :created
      end

      def show
        render jsonapi: @inventory_column, serializer: InventoryColumnSerializer
      end

      def update
        @inventory_column.attributes = update_inventory_column_params
        if @inventory_column.changed? && @inventory_column.save!
          render jsonapi: @inventory_column,
                          serializer: InventoryColumnSerializer
        else
          render body: nil
        end
      end

      def destroy
        @inventory_column.destroy!
        render body: nil
      end

      private

      def load_team
        @team = Team.find(params.require(:team_id))
        render jsonapi: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_inventory
        @inventory = @team.repositories.find(params.require(:inventory_id))
      end

      def load_inventory_column
        @inventory_column = @inventory.repository_columns
                                      .find(params.require(:id))
      end

      def check_manage_permissions
        unless can_manage_repository_column?(@inventory_column)
          render body: nil, status: :forbidden
        end
      end

      def inventory_column_params
        unless params.require(:data).require(:type) == 'inventory_columns'
          raise ActionController::BadRequest,
                'Wrong object type within parameters'
        end
        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(name) })[:data]
      end

      def update_inventory_column_params
        unless params.require(:data).require(:id).to_i == params[:id].to_i
          raise ActionController::BadRequest,
                'Object ID mismatch in URL and request body'
        end
        inventory_column_params[:attributes]
      end
    end
  end
end
