# frozen_string_literal: true

module Api
  module V1
    class InventoryStatusItemSerializer < ActiveModel::Serializer
      type :inventory_status_items
      attributes :status, :icon

      include TimestampableModel
    end
  end
end
