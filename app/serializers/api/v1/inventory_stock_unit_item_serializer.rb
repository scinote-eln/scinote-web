# frozen_string_literal: true

module Api
  module V1
    class InventoryStockUnitItemSerializer < ActiveModel::Serializer
      type :inventory_stock_unit_items
      attributes :id, :data

      include TimestampableModel
    end
  end
end
