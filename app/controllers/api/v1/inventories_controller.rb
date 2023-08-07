# frozen_string_literal: true

module Api
  module V1
    class InventoriesController < BaseController
      before_action :load_team
      before_action only: %i(show update destroy) do
        load_inventory(:id)
      end
      before_action :check_manage_permissions, only: :update
      before_action :check_delete_permissions, only: :destroy

      def index
        inventories =
          timestamps_filter(@team.repositories).active
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

        return render body: nil, status: :no_content unless @inventory.changed?

        if @inventory.archived_changed?
          @inventory.archived? ? @inventory.archive(current_user) : @inventory.restore(current_user)
        end
        @inventory.save!
        render jsonapi: @inventory, serializer: InventorySerializer
      end

      def destroy
        @inventory.destroy!
        render body: nil
      end

      private

      def check_manage_permissions
        if update_inventory_params.keys.excluding('archived').present?
          raise PermissionError.new(Repository, :manage) unless can_manage_repository?(@inventory)
        elsif update_inventory_params.key?('archived')
          raise PermissionError.new(Repository, :archive) unless can_archive_repository?(@inventory)
        end
      end

      def check_delete_permissions
        raise PermissionError.new(Repository, :delete) unless can_delete_repository?(@inventory)
      end

      def inventory_params
        unless params.require(:data).require(:type) == 'inventories'
          raise TypeError
        end
        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(name archived) })[:data]
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
