# frozen_string_literal: true

module Api
  module V2
    class InventoryItemChildRelationshipsController < BaseController
      before_action :load_team, :load_inventory, :load_inventory_item
      before_action :load_child_connection, only: %w(show destroy)
      before_action :check_manage_permission, only: %w(create destroy)

      def index
        child_connections = timestamps_filter(@inventory_item.child_connections).page(params.dig(:page, :number))
                                                                                .per(params.dig(:page, :size))
        render jsonapi: child_connections, each_serializer: InventoryItemRelationshipSerializer, include: include_params
      end

      def show
        render jsonapi: @child_connection, serializer: InventoryItemRelationshipSerializer, include: include_params
      end

      def create
        inventory_item_to_link = RepositoryRow.where(repository: Repository.accessible_by_teams(@team))
                                              .find(connection_params[:child_id])
        child_connection = @inventory_item.child_connections.create!(
          child: inventory_item_to_link,
          created_by: current_user,
          last_modified_by: current_user
        )

        render jsonapi: child_connection, serializer: InventoryItemRelationshipSerializer, status: :created
      end

      def destroy
        @child_connection.destroy!
        render body: nil
      end

      private

      def load_child_connection
        @child_connection = @inventory_item.child_connections.find(params.require(:id))
      end

      def check_manage_permission
        raise PermissionError.new(Repository, :manage) unless can_connect_repository_rows?(@inventory)
      end

      def connection_params
        raise TypeError unless params.require(:data).require(:type) == 'inventory_item_relationships'

        params.require(:data).require(:attributes).permit(:child_id)
      end

      def permitted_includes
        %w(child)
      end
    end
  end
end
