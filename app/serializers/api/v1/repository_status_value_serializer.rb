# frozen_string_literal: true

module Api
  module V1
    class RepositoryStatusValueSerializer < ActiveModel::Serializer
      attribute :repository_status_item_id, key: :inventory_status_item_id
      attribute :inventory_status_item_icon do
        object.repository_status_item.icon
      end
      attribute :inventory_status_item_name do
        object.repository_status_item.status
      end

      include TimestampableModel
    end
  end
end
