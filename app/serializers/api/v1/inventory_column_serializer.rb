# frozen_string_literal: true

module Api
  module V1
    class InventoryColumnSerializer < ActiveModel::Serializer
      type :inventory_columns
      attributes :name, :data_type
      has_many :repository_list_items, key: :inventory_list_items,
                                       serializer: InventoryListItemSerializer,
                                       class_name: 'RepositoryListItem'
    end
  end
end
