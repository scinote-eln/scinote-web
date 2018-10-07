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
      belongs_to :repository, key: :inventory,
                              serializer: InventorySerializer,
                              class_name: 'Repository',
                              if: -> { instance_options[:show_repository] }
    end
  end
end
