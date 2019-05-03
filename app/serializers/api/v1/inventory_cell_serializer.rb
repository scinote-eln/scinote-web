# frozen_string_literal: true

module Api
  module V1
    class InventoryCellSerializer < ActiveModel::Serializer
      type :inventory_cells
      attributes :id, :value_type, :value
      attribute :repository_column_id, key: :column_id

      def value
        ActiveModelSerializers::SerializableResource.new(
          object.value,
          class_name: object.value_type,
          namespace: Api::V1,
          adapter: :attribute
        ).as_json
      end

      def value_type
        Extends::API_REPOSITORY_DATA_TYPE_MAPPINGS[object.value_type]
      end
    end
  end
end
