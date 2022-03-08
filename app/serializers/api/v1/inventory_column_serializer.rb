# frozen_string_literal: true

module Api
  module V1
    class InventoryColumnSerializer < ActiveModel::Serializer
      type :inventory_columns
      attributes :name, :data_type
      has_many :repository_list_items,
               key: :inventory_list_items,
               serializer: InventoryListItemSerializer,
               class_name: 'RepositoryListItem',
               if: (lambda do
                 object.data_type == 'RepositoryListValue' &&
                   !instance_options[:hide_list_items]
               end)

      def data_type
        Extends::API_REPOSITORY_DATA_TYPE_MAPPINGS[object.data_type]
      end
    end
  end
end
