# frozen_string_literal: true

module Api
  module V1
    class InventoryItemsController < BaseController
      before_action :load_team
      before_action :load_inventory
      before_action only: %i(show update destroy) do
        load_inventory_item(:id)
      end
      before_action :check_manage_permissions, only: %i(create update)
      before_action :check_delete_permissions, only: :destroy

      def index
        items =
          timestamps_filter(
            @inventory.repository_rows
          )
          .active
          .preload(repository_cells: :repository_column)
          .preload(repository_cells: { value: @inventory.cell_preload_includes })
          .page(params.dig(:page, :number))
          .per(params.dig(:page, :size))
          .order(:id)

        render jsonapi: items, each_serializer: InventoryItemSerializer, include: include_params
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
              RepositoryCell.create_with_value!(
                item, column, cell_attributes[:value], current_user
              )
            end
          end
        else
          item = @inventory.repository_rows.create!(attributes)
        end
        render jsonapi: item,
               serializer: InventoryItemSerializer,
               include: :inventory_cells,
               status: :created
      end

      def show
        render jsonapi: @inventory_item,
               serializer: InventoryItemSerializer,
               include: :inventory_cells
      end

      def update
        item_changed = false
        if inventory_cells_params.present?
          inventory_cells_params.each do |p|
            p.require(%i(id attributes))
            p.require(:attributes).require(:value)
          end
          @inventory_item.with_lock do
            inventory_cells_params.each do |cell_params|
              cell = @inventory_item.repository_cells.find(cell_params[:id])
              cell_value = cell_params.dig(:attributes, :value)
              next unless cell.value.data_different?(cell_value)

              cell.value.update_data!(cell_value, current_user)
              item_changed = true
            end
          end
        end
        @inventory_item.attributes = update_inventory_item_params
        item_changed = true if @inventory_item.changed?
        if item_changed
          if @inventory_item.archived_changed?
            @inventory_item.archived? ? @inventory_item.archive(current_user) : @inventory_item.restore(current_user)
          end
          @inventory_item.last_modified_by = current_user
          @inventory_item.save!
          render jsonapi: @inventory_item,
                 serializer: InventoryItemSerializer,
                 include: :inventory_cells
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @inventory_item.destroy!
        render body: nil
      end

      private

      def check_manage_permissions
        raise PermissionError.new(RepositoryRow, :manage) unless can_manage_repository_rows?(@inventory)
      end

      def check_delete_permissions
        unless can_delete_repository_rows?(@inventory) && @inventory_item.archived?
          raise PermissionError.new(RepositoryRow, :delete)
        end
      end

      def inventory_item_params
        raise TypeError unless params.require(:data).require(:type) == 'inventory_items'

        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(name archived) })[:data]
      end

      def update_inventory_item_params
        raise IDMismatchError unless params.require(:data).require(:id).to_i == params[:id].to_i

        inventory_item_params[:attributes]
      end

      # Partially implement sideposting draft
      # https://github.com/json-api/json-api/pull/1197
      def inventory_cells_params
        params[:included]&.select { |el| el[:type] == 'inventory_cells' }
      end

      def permitted_includes
        %w(inventory_cells)
      end
    end
  end
end
