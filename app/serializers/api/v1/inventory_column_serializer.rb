# frozen_string_literal: true

module Api
  module V1
    class InventoryColumnSerializer < ActiveModel::Serializer
      type :inventory_columns
      attributes :name, :data_type
      has_many :repository_list_items, key: :inventory_list_items,
                                       serializer: InventoryListItemSerializer,
                                       class_name: 'RepositoryListItem'

      def data_type
        type_id = RepositoryColumn
                  .data_types[object.data_type]
        I18n.t("api.v1.inventory_data_types.t#{type_id}")
      end
    end
  end
end
