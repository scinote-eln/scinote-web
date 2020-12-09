# frozen_string_literal: true

module Api
  module V1
    class InventoryChecklistItemSerializer < ActiveModel::Serializer
      type :inventory_checklist_items
      attributes :id, :data
<<<<<<< HEAD

      include TimestampableModel
=======
>>>>>>> Pulled latest release
    end
  end
end
