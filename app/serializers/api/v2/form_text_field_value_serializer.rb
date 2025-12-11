# frozen_string_literal: true

module Api
  module V2
    class FormTextFieldValueSerializer < ActiveModel::Serializer
      type :form_field_values
      attributes :id, :value, :value_type, :form_field_id

      belongs_to :form_field, serializer: Api::V2::FormFieldSerializer

      def value
        object.value
      end

      def value_type
        'text'
      end

      include TimestampableModel
    end
  end
end
