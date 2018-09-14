# frozen_string_literal: true

module Api
  module V1
    class InventoryCellSerializer < ActiveModel::Serializer
      type :inventory_cells
      attributes :id, :value_type, :value
      attribute :repository_column_id, key: :column_id

      def value_type
        type_id = RepositoryColumn
                  .data_types[object.repository_column.data_type]
        I18n.t("api.v1.inventory_data_types.t#{type_id}")
      end

      def value
        value =
          case object.value_type
          when 'RepositoryTextValue'
            object.repository_text_value
          when 'RepositoryDateValue'
            object.repository_date_value
          when 'RepositoryListValue'
            object.repository_list_value
          when 'RepositoryAssetValue'
            object.repository_asset_value
          end
        ActiveModelSerializers::SerializableResource.new(
          value,
          namespace: Api::V1,
          adapter: :attribute
        ).as_json
      end
    end
  end
end
