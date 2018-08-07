module Api
  module V1
    class InventoryItemsController < BaseController
      before_action :load_team
      before_action :load_inventory

      def index
        items =
          @inventory.repository_rows
                    .includes(repository_cells: :repository_column)
                    .includes(
                      repository_cells: Extends::REPOSITORY_SEARCH_INCLUDES
                    ).page(params[:page])
                    .per(params[:page_size])
        render json: items,
               each_serializer: InventoryItemSerializer,
               include: :inventory_cells
      end

      private

      def load_team
        @team = Team.find(params.require(:team_id))
        return render json: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_inventory
        @inventory = @team.repositories.find(params.require(:inventory_id))
      end
    end
  end
end
