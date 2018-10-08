# frozen_string_literal: true

module Api
  module V1
    class InventoryCellsController < BaseController
      before_action :load_vars
      before_action :load_inventory_cell, only: %i(show update destroy)
      before_action :check_manage_permissions, only: %i(create update destroy)

      def index
        cells = @inventory_item.repository_cells
                               .includes(Extends::REPOSITORY_SEARCH_INCLUDES)
                               .page(params.dig(:page, :number))
                               .per(params.dig(:page, :size))
        render jsonapi: cells, each_serializer: InventoryCellSerializer
      end

      def create
        column = @inventory.repository_columns
                           .find(inventory_cell_params[:column_id])
        cell = RepositoryCell.create_with_value!(@inventory_item,
                                                 column,
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

      def load_vars
        @team = Team.find(params.require(:team_id))
        unless can_read_team?(@team)
          return render jsonapi: {}, status: :forbidden
        end
        @inventory = @team.repositories.find(params.require(:inventory_id))
        @inventory_item = @inventory.repository_rows.find(params[:item_id].to_i)
      end

      def load_inventory_cell
        @inventory_cell = @inventory_item.repository_cells
                                         .find(params[:id].to_i)
      end

      def check_manage_permissions
        unless can_manage_repository_rows?(@team)
          render body: nil, status: :forbidden
        end
      end

      def inventory_cell_params
        unless params.require(:data).require(:type) == 'inventory_cells'
          raise ActionController::BadRequest,
                'Wrong object type within parameters'
        end
        params.require(:data).require(:attributes).require(:column_id)
        params.require(:data).require(:attributes).require(:value)
        params[:data][:attributes]
      end

      def update_inventory_cell_params
        unless params.require(:data).require(:id).to_i == params[:id].to_i
          raise ActionController::BadRequest,
                'Object ID mismatch in URL and request body'
        end
        inventory_cell_params
      end
    end
  end
end
