# frozen_string_literal: true

module Api
  module V1
    class InventoryColumnsController < BaseController
      before_action :load_team
      before_action :load_inventory
      before_action only: %i(show update destroy) do
        load_inventory_column(:id)
      end
      before_action :check_manage_permissions, only: %i(update destroy)
      before_action :check_create_permissions, only: %i(create)

      def index
        columns = @inventory.repository_columns
                            .includes(:repository_list_items)
                            .includes(:repository_status_items)
                            .page(params.dig(:page, :number))
                            .per(params.dig(:page, :size))
        render jsonapi: columns,
               each_serializer: InventoryColumnSerializer,
               hide_list_items: true
      end

      def create
        inventory_column =
          @inventory.repository_columns.create!(inventory_column_params)
        render jsonapi: inventory_column,
               serializer: InventoryColumnSerializer,
               hide_list_items: true,
               status: :created
      end

      def show
        render jsonapi: @inventory_column,
               serializer: InventoryColumnSerializer,
               include: :inventory_list_items
      end

      def update
        @inventory_column.attributes = update_inventory_column_params
        if @inventory_column.data_type == "RepositoryStockValue"
          if @inventory_column.changed?
            @inventory_column.update_column(:metadata, update_inventory_column_params[:metadata])
          end
          if update_inventory_column_params[:repository_stock_unit_items_attributes].present?
            @inventory_column = RepositoryColumns::UpdateStockColumnService
                      .call(user: @current_user,
                            team: @team,
                            column: @inventory_column,
                            params: update_inventory_column_params)
          end
          render jsonapi: load_inventory_column(:id), # if not loaded again ouput is without new unit items
                          serializer: InventoryColumnSerializer,
                          hide_list_items: true
        elsif @inventory_column.changed? && @inventory_column.save!
          render jsonapi: @inventory_column,
                          serializer: InventoryColumnSerializer,
                          hide_list_items: true
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        if @inventory_column.data_type != "RepositoryStockValue"
          @inventory_column.destroy!
          render body: nil
        else
          render body: nil, status: :method_not_allowed
        end
      end

      private

      def check_manage_permissions
        raise PermissionError.new(RepositoryColumn, :manage) unless can_manage_repository_column?(@inventory_column)
      end

      def check_create_permissions
        raise PermissionError.new(RepositoryColumn, :create) unless can_create_repository_columns?(@inventory)
      end

      def inventory_column_params
        raise TypeError unless params.require(:data).require(:type) == 'inventory_columns'

        params.require(:data).require(:attributes)
        new_params = params
                     .permit(data: { attributes: [:name, :data_type, metadata: {}, repository_stock_unit_items_attributes: %i(data)] })[:data]
                     .merge(created_by: @current_user)
        if new_params[:attributes][:data_type].present?
          new_params[:attributes][:data_type] =
            Extends::API_REPOSITORY_DATA_TYPE_MAPPINGS
            .key(new_params.dig(:attributes, :data_type))
        end

        new_params[:attributes][:repository_stock_unit_items_attributes]&.map do |m|
          m.merge!(created_by_id: @current_user.id, last_modified_by_id: @current_user.id)
        end

        new_params
      end

      def update_inventory_column_params
        raise IDMismatchError unless params.require(:data).require(:id).to_i == params[:id].to_i

        if inventory_column_params[:attributes].include?(:data_type)
          raise ActiveRecord::RecordInvalid,
                I18n.t('api.core.errors.inventory_column_type.detail')
        end
        inventory_column_params[:attributes]
      end
    end
  end
end
