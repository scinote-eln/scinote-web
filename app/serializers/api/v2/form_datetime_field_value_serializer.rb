# frozen_string_literal: true

module Api
  module V2
    class FormDatetimeFieldValueSerializer < ActiveModel::Serializer
      type :form_field_values
      attributes :id, :value, :value_type

      def value
        object.value
      end

      def value_type
        object.range? ? 'date_time_range' : 'date_time'
      end

      include TimestampableModel
    end
  end
end
