# frozen_string_literal: true

module Api
  module V2
    class FormMultipleChoiceFieldValueSerializer < ActiveModel::Serializer
      type :form_field_values
      attributes :id, :value, :value_type

      def value
        object.value
      end

      def value_type
        'multiple_choice'
      end

      include TimestampableModel
    end
  end
end
