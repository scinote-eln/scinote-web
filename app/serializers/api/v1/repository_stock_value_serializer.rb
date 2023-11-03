# frozen_string_literal: true

module Api
  module V1
    class RepositoryStockValueSerializer < ActiveModel::Serializer
      attribute :repository_stock_unit_item_id, key: :inventory_stock_unit_item_id
      attributes :amount, :low_stock_threshold, :comment

      include TimestampableModel
    end
  end
end
