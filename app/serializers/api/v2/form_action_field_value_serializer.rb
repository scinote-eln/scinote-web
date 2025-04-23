# frozen_string_literal: true

module Api
  module V2
    class FormActionFieldValueSerializer < ActiveModel::Serializer
      type :form_field_values
      attributes :id, :value, :value_type

      def value
        object.formatted
      end

      def value_type
        'action'
      end

      include TimestampableModel
    end
  end
end
