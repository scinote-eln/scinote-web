# frozen_string_literal: true

module Api
  module V2
    class InventoryItemRelationshipSerializer < ActiveModel::Serializer
      type :inventory_item_relationships

      belongs_to :parent, serializer: InventoryItemSerializer
      belongs_to :child, serializer: InventoryItemSerializer
      belongs_to :created_by, serializer: UserSerializer
      belongs_to :last_modified_by, serializer: UserSerializer
    end
  end
end
