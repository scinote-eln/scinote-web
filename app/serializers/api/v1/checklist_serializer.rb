# frozen_string_literal: true

module Api
  module V1
    class ChecklistSerializer < ActiveModel::Serializer
      type :checklists
      attributes :id, :name, :position, :archived, :locked
      has_many :checklist_items, serializer: ChecklistItemSerializer

      def position
        object&.step_orderable_element&.position
      end

      def locked
        object.locked || object.step.locked
      end

      include TimestampableModel
    end
  end
end
