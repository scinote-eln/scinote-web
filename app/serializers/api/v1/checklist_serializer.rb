# frozen_string_literal: true

module Api
  module V1
    class ChecklistSerializer < ActiveModel::Serializer
      type :checklists
      attributes :id, :name
      has_many :checklist_items, serializer: ChecklistItemSerializer
<<<<<<< HEAD

      include TimestampableModel
=======
>>>>>>> Pulled latest release
    end
  end
end
