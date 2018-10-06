# frozen_string_literal: true

module Api
  module V1
    class InventoryItemSerializer < ActiveModel::Serializer
      type :inventory_items
      attributes :name
      has_many :repository_cells, key: :inventory_cells,
                                  serializer: InventoryCellSerializer,
                                  class_name: 'RepositoryCell',
                                  unless: -> { object.repository_cells.empty? }
    end
  end
end
