# frozen_string_literal: true

module Api
  module V1
    class InventoryChecklistItemSerializer < ActiveModel::Serializer
      type :inventory_checklist_items
      attributes :id, :data

      include TimestampableModel
    end
  end
end
