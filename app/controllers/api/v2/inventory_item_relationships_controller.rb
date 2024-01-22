# frozen_string_literal: true

module Api
  module V2
    class InventoryItemRelationshipsController < BaseController
      before_action :load_team, :load_inventory, :load_inventory_item
      before_action :check_manage_permission, only: %w(create destroy)
      before_action :load_create_params, only: :create

      def create
        parent = @relation == :parent ? @inventory_item : @inventory_item_to_link
        child = @relation == :child ? @inventory_item : @inventory_item_to_link

        @connection = RepositoryRowConnection.create!(
          parent: parent,
          child: child,
          created_by: current_user,
          last_modified_by: current_user
        )

        render jsonapi: @connection, serializer: InventoryItemRelationshipSerializer, status: :created
      end

      def destroy
        @connection = @inventory_item.parent_connections
                                     .or(@inventory_item.child_connections)
                                     .find(params.require(:id))
        @connection.destroy!
        render body: nil
      end

      private

      def check_manage_permission
        raise PermissionError.new(Repository, :manage) unless can_manage_repository?(@inventory)
      end

      def load_create_params
        if connection_params[:parent_id].present? && connection_params[:child_id].present?
          raise MutuallyExclusiveParamsError.new(:parent_id, :child_id)
        end

        if connection_params[:parent_id].present?
          @relation = :parent
          @inventory_item_to_link = RepositoryRow.find(connection_params[:parent_id])
        elsif connection_params[:child_id].present?
          @relation = :child
          @inventory_item_to_link = RepositoryRow.find(connection_params[:child_id])
        end

        raise ActiveRecord::RecordNotFound unless @inventory_item_to_link
      end

      def connection_params
        raise TypeError unless params.require(:data).require(:type) == 'inventory_item_relationships'

        params.require(:data).require(:attributes).permit(%i(parent_id child_id))
      end

      def permitted_includes
        %w(parent child)
      end
    end
  end
end
