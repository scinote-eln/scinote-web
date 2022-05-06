# frozen_string_literal: true

module Api
  module V1
    class InventoryColumnSerializer < ActiveModel::Serializer
      type :inventory_columns
      attributes :name, :data_type, :metadata
      has_many :repository_list_items,
               key: :inventory_list_items,
               serializer: InventoryListItemSerializer,
               class_name: 'RepositoryListItem',
               if: (lambda do
                 object.data_type == 'RepositoryListValue' &&
                   !instance_options[:hide_list_items]
               end)
      has_many :repository_checklist_items,
               key: :inventory_checklist_items,
               serializer: InventoryChecklistItemSerializer,
               class_name: 'RepositoryChecklistItem',
               if: (lambda do
                 object.data_type == 'RepositoryChecklistValue' &&
                  !instance_options[:hide_list_items]
               end)
      has_many :repository_status_items,
               key: :inventory_status_items,
               serializer: InventoryStatusItemSerializer,
               class_name: 'RepositoryStatusItem',
               if: (lambda do
                 object.data_type == 'RepositoryStatusValue' &&
                   !instance_options[:hide_list_items]
               end)
      has_many :repository_stock_unit_items,
               key: :inventory_stock_unit_items,
               serializer: InventoryStockUnitItemSerializer,
               class_name: 'RepositoryStockUnitItem',
               if: (lambda do
                 object.data_type == 'RepositoryStockValue' &&
                   !instance_options[:hide_list_items]
               end)

      include TimestampableModel

      def data_type
        Extends::API_REPOSITORY_DATA_TYPE_MAPPINGS[object.data_type]
      end
    end
  end
end
