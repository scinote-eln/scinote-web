# frozen_string_literal: true

module Api
  module V1
    class InventoryListItemSerializer < ActiveModel::Serializer
      type :inventory_list_items
      attribute :data
    end
  end
end
