# frozen_string_literal: true

module Api
  module V1
    class InventoriesController < BaseController
      before_action :load_team
      before_action only: %i(show update destroy) do
        load_inventory(:id)
      end
      before_action :check_manage_permissions, only: %i(update destroy)

      def index
        inventories = @team.repositories
                           .page(params.dig(:page, :number))
                           .per(params.dig(:page, :size))
        render jsonapi: inventories, each_serializer: InventorySerializer
      end

      def create
        unless can_create_repositories?(@team)
          raise PermissionError.new(Repository, :create)
        end
        inventory = @team.repositories.create!(
          inventory_params.merge(created_by: current_user)
        )
        render jsonapi: inventory,
               serializer: InventorySerializer,
               status: :created
      end

      def show
        render jsonapi: @inventory,
               serializer: InventorySerializer,
               include: :created_by
      end

      def update
        @inventory.attributes = update_inventory_params
        if @inventory.changed? && @inventory.save!
          render jsonapi: @inventory, serializer: InventorySerializer
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @inventory.destroy!
        render body: nil
      end

      private

      def check_manage_permissions
        unless can_manage_repository?(@inventory)
          raise PermissionError.new(Repository, :manage)
        end
      end

      def inventory_params
        unless params.require(:data).require(:type) == 'inventories'
          raise TypeError
        end
        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(name) })[:data]
      end

      def update_inventory_params
        unless params.require(:data).require(:id).to_i == params[:id].to_i
          raise IDMismatchError
        end
        inventory_params[:attributes]
      end
    end
  end
end
