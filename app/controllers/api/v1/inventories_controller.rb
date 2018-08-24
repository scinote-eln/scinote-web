# frozen_string_literal: true

module Api
  module V1
    class InventoriesController < BaseController
      before_action :load_team
      before_action :load_inventory, only: %i(show update destroy)
      before_action :check_manage_permissions, only: %i(create update destroy)

      def index
        inventories = @team.repositories
                           .page(params.dig(:page, :number))
                           .per(params.dig(:page, :size))
        render jsonapi: inventories, each_serializer: InventorySerializer
      end

      def create
        inventory = @team.repositories.create!(inventory_params)
        render jsonapi: inventory,
               serializer: InventorySerializer,
               status: :created
      end

      def show
        render jsonapi: @inventory, serializer: InventorySerializer
      end

      def update
        @inventory.attributes = update_inventory_params
        if @inventory.changed? && @inventory.save!
          render jsonapi: @inventory, serializer: InventorySerializer
        else
          render body: nil
        end
      end

      def destroy
        @inventory.destroy!
        render body: nil
      end

      private

      def load_team
        @team = Team.find(params.require(:team_id))
        render jsonapi: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_inventory
        @inventory = @team.repositories.find(params.require(:id))
      end

      def check_manage_permissions
        unless can_manage_repository?(@inventory)
          render body: nil, status: :forbidden
        end
      end

      def inventory_params
        unless params.require(:data).require(:type) == 'inventories'
          raise ActionController::BadRequest,
                'Wrong object type within parameters'
        end
        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(name) })[:data]
      end

      def update_inventory_params
        unless params.require(:data).require(:id).to_i == params[:id].to_i
          raise ActionController::BadRequest,
                'Object ID mismatch in URL and request body'
        end
        inventory_params[:attributes]
      end
    end
  end
end
