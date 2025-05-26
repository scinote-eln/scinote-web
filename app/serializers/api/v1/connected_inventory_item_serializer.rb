# frozen_string_literal: true

module Api
  module V1
    class ConnectedInventoryItemSerializer < InventoryItemSerializer
      belongs_to :repository, key: :inventory, serializer: InventorySerializer
    end
  end
end
