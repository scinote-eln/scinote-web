# frozen_string_literal: true

module Api
  module V1
    class InventoryItemSerializer < ActiveModel::Serializer
      type :inventory_items
      attributes :name, :archived
      attribute :stock_consumption, if: -> { object.repository_stock_cell.present? }
      has_many :repository_cells, key: :inventory_cells,
                                  serializer: InventoryCellSerializer,
                                  class_name: 'RepositoryCell',
                                  unless: -> { object.repository_cells.blank? }
      belongs_to :repository, key: :inventory,
                              serializer: InventorySerializer,
                              class_name: 'Repository',
                              if: -> { instance_options[:show_repository] }

      include TimestampableModel
    end
  end
end
