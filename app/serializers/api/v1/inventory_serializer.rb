# frozen_string_literal: true

module Api
  module V1
    class InventorySerializer < ActiveModel::Serializer
      type :inventories
      attributes :id, :name
      belongs_to :created_by, serializer: UserSerializer
    end
  end
end
