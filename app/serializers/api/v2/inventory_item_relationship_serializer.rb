# frozen_string_literal: true

module Api
  module V2
    class InventoryItemRelationshipSerializer < ActiveModel::Serializer
      type :inventory_item_relationships

      belongs_to :parent, serializer: Api::V1::InventoryItemSerializer
      belongs_to :child, serializer: Api::V1::InventoryItemSerializer
      belongs_to :created_by, serializer: Api::V1::UserSerializer
      belongs_to :last_modified_by, serializer: Api::V1::UserSerializer
    end
  end
end
