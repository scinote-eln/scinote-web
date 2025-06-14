# frozen_string_literal: true

module Api
  module V1
    class InventoryItemSerializer < ActiveModel::Serializer
      type :inventory_items
      attributes :name, :archived, :archived_on
      has_many :repository_cells, key: :inventory_cells,
                                  serializer: InventoryCellSerializer,
                                  class_name: 'RepositoryCell',
                                  unless: -> { object.repository_cells.blank? }
      belongs_to :repository, key: :inventory,
                              serializer: InventorySerializer,
                              class_name: 'Repository',
                              if: -> { instance_options[:show_repository] }
      has_many :parent_repository_rows, key: :parents,
                                        serializer: Api::V1::ConnectedInventoryItemSerializer
      has_many :child_repository_rows, key: :children,
                                       serializer: Api::V1::ConnectedInventoryItemSerializer

      include TimestampableModel
    end
  end
end
