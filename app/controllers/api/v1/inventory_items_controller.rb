# frozen_string_literal: true

module Api
  module V1
    class InventoryItemsController < BaseController
      before_action :load_team
      before_action :load_inventory
      before_action :check_manage_permissions, only: %i(create)

      def index
        items =
          @inventory.repository_rows
                    .includes(repository_cells: :repository_column)
                    .includes(
                      repository_cells: Extends::REPOSITORY_SEARCH_INCLUDES
                    ).page(params.dig(:page, :number))
                    .per(params.dig(:page, :size))
        render json: items,
               each_serializer: InventoryItemSerializer,
               include: :inventory_cells
      end

      def create
        attributes = inventory_item_params.merge(
          created_by: current_user,
          last_modified_by: current_user
        )
        if inventory_cells_params.present?
          inventory_cells_params
            .each { |p| p.require(:attributes).require(%i(column_id value)) }
          item = @inventory.repository_rows.new(attributes)
          item.transaction do
            item.save!
            inventory_cells_params.each do |cell_params|
              cell_attributes = cell_params[:attributes]
              column =
                @inventory.repository_columns.find(cell_attributes[:column_id])
              RepositoryCell.create_with_value(
                item, column, cell_attributes[:value], current_user
              )
            end
          end
        else
          item = @inventory.repository_rows.create!(attributes)
        end
        render json: item,
               serializer: InventoryItemSerializer,
               include: :inventory_cells,
               status: :created
      end

      private

      def load_team
        @team = Team.find(params.require(:team_id))
        return render json: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_inventory
        @inventory = @team.repositories.find(params.require(:inventory_id))
      end

      def check_manage_permissions
        unless can_manage_repository_rows?(@team)
          render body: nil, status: :forbidden
        end
      end

      def inventory_item_params
        unless params.require(:data).require(:type) == 'inventory_items'
          raise ActionController::BadRequest,
                'Wrong object type within parameters'
        end
        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(name uid) })[:data]
      end

      # Partially implement sideposting draft
      # https://github.com/json-api/json-api/pull/1197
      def inventory_cells_params
        params[:included]&.select { |el| el[:type] == 'inventory_cells' }
      end
    end
  end
end
