# frozen_string_literal: true

module Api
  module V1
    class ChecklistItemSerializer < ActiveModel::Serializer
      type :checklist_items
      attributes :id, :text, :checked, :position

      include TimestampableModel
    end
  end
end
