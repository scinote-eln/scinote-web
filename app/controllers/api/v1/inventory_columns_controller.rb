# frozen_string_literal: true

module Api
  module V1
    class InventoryColumnsController < BaseController
      before_action :load_team
      before_action :load_inventory

      def index
        columns = @inventory.repository_columns
                            .includes(:repository_list_items)
                            .page(params[:page])
                            .per(params[:page_size])
        render json: columns, each_serializer: InventoryColumnSerializer,
        include: :inventory_list_items
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
