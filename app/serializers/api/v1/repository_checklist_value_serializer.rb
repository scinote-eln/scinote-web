# frozen_string_literal: true

module Api
  module V1
    class RepositoryChecklistValueSerializer < ActiveModel::Serializer
      attribute :inventory_checklist_item_ids do
        object.repository_checklist_items.pluck(:id)
      end
      attribute :inventory_checklist_item_names do
        object.repository_checklist_items.pluck(:data)
      end

      include TimestampableModel
    end
  end
end
