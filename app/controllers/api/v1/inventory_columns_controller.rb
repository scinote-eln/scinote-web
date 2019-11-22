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
        if @inventory_column.changed? && @inventory_column.save!
          render jsonapi: @inventory_column,
                          serializer: InventoryColumnSerializer,
                          hide_list_items: true
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @inventory_column.destroy!
        render body: nil
      end

      private

      def check_manage_permissions
        unless can_manage_repository_column?(@inventory_column)
          raise PermissionError.new(RepositoryColumn, :manage)
        end
      end

      def check_create_permissions
        raise PermissionError.new(RepositoryColumn, :create) unless can_create_repository_columns?(@inventory)
      end

      def inventory_column_params
        unless params.require(:data).require(:type) == 'inventory_columns'
          raise TypeError
        end
        params.require(:data).require(:attributes)
        new_params = params
                     .permit(data: { attributes: %i(name data_type) })[:data]
                     .merge(created_by: @current_user)
        if new_params[:attributes][:data_type].present?
          new_params[:attributes][:data_type] =
            Extends::API_REPOSITORY_DATA_TYPE_MAPPINGS
            .key(new_params.dig(:attributes, :data_type))
        end
        new_params
      end

      def update_inventory_column_params
        unless params.require(:data).require(:id).to_i == params[:id].to_i
          raise IDMismatchError
        end
        if inventory_column_params[:attributes].include?(:data_type)
          raise ActiveRecord::RecordInvalid,
                I18n.t('api.core.errors.inventory_column_type.detail')
        end
        inventory_column_params[:attributes]
      end
    end
  end
end
