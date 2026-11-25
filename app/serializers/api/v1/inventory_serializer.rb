# frozen_string_literal: true

module Api
  module V1
    class InventorySerializer < ActiveModel::Serializer
      type :inventories
      attributes :id, :name, :archived
      attribute :enforce_unique_item_names, if: -> { RepositoryBase.inventory_integrity_enabled? }
      attribute :unique_item_names_case_sensitive, if: -> { RepositoryBase.inventory_integrity_enabled? }
      belongs_to :created_by, serializer: UserSerializer

      include TimestampableModel
    end
  end
end
