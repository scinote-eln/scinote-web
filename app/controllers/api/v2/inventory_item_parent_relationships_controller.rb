# frozen_string_literal: true

module Api
  module V2
    class InventoryItemParentRelationshipsController < BaseController
      before_action :load_team, :load_inventory, :load_inventory_item
      before_action :load_parent_connection, only: %w(show destroy)
      before_action :check_manage_permission, only: %w(create destroy)

      def index
        parent_connections = timestamps_filter(@inventory_item.parent_connections).page(params.dig(:page, :number))
                                                                                  .per(params.dig(:page, :size))
        render jsonapi: parent_connections,
               each_serializer: InventoryItemRelationshipSerializer,
               include: include_params
      end

      def show
        render jsonapi: @parent_connection, serializer: InventoryItemRelationshipSerializer, include: include_params
      end

      def create
        inventory_item_to_link = RepositoryRow.where(repository: Repository.accessible_by_teams(@team))
                                              .find(connection_params[:parent_id])
        parent_connection = @inventory_item.parent_connections.create!(
          parent: inventory_item_to_link,
          created_by: current_user,
          last_modified_by: current_user
        )

        render jsonapi: parent_connection, serializer: InventoryItemRelationshipSerializer, status: :created
      end

      def destroy
        @parent_connection.destroy!
        render body: nil
      end

      private

      def load_parent_connection
        @parent_connection = @inventory_item.parent_connections.find(params.require(:id))
      end

      def check_manage_permission
        raise PermissionError.new(Repository, :manage) unless can_connect_repository_rows?(@inventory)
      end

      def connection_params
        raise TypeError unless params.require(:data).require(:type) == 'inventory_item_relationships'

        params.require(:data).require(:attributes).permit(:parent_id)
      end

      def permitted_includes
        %w(parent)
      end
    end
  end
end
