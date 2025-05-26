# frozen_string_literal: true

module Api
  module V1
    class ConnectedInventoryItemSerializer < ActiveModel::Serializer
      type :inventory_items
      attributes :name, :archived
      has_many :repository_cells, key: :inventory_cells,
                                  serializer: InventoryCellSerializer,
                                  class_name: 'RepositoryCell',
                                  unless: -> { object.repository_cells.blank? }
      belongs_to :repository, key: :inventory,
                              serializer: InventorySerializer
      has_many :parent_repository_rows, key: :parents,
                                        serializer: self
      has_many :child_repository_rows, key: :children,
                                       serializer: self

      include TimestampableModel
    end
  end
end
