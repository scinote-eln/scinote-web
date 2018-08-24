# frozen_string_literal: true

module Api
  module V1
    class InventoriesController < BaseController
      before_action :load_team, only: %i(show index)
      before_action :load_inventory, only: %i(show)

      def index
        inventories = @team.repositories
                           .page(params.dig(:page, :number))
                           .per(params.dig(:page, :size))
        render jsonapi: inventories, each_serializer: InventorySerializer
      end

      def show
        render jsonapi: @inventory, serializer: InventorySerializer
      end

      private

      def load_team
        @team = Team.find(params.require(:team_id))
        render jsonapi: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_inventory
        @inventory = @team.repositories.find(params.require(:id))
      end
    end
  end
end
