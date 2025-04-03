# frozen_string_literal: true

module Api
  module V2
    class FormRepositoryRowsFieldValueSerializer < ActiveModel::Serializer
      type :form_field_values
      attributes :id, :value, :value_type

      def value
        object.data&.map { |repository_row| { id: repository_row['id'], inventory_id: repository_row['repository_id'] } }
      end

      def value_type
        'inventory_items'
      end

      include TimestampableModel
    end
  end
end
