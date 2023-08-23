# frozen_string_literal: true

module Api
  module V1
    class ChecklistSerializer < ActiveModel::Serializer
      type :checklists
      attributes :id, :name, :position
      has_many :checklist_items, serializer: ChecklistItemSerializer

      def position
        object&.step_orderable_element&.position
      end

      include TimestampableModel
    end
  end
end
