# frozen_string_literal: true

module Api
  module V2
    class FormSingleChoiceFieldValueSerializer < ActiveModel::Serializer
      type :form_action_field_values
      attributes :id, :value, :value_type

      def value
        object.value
      end

      def value_type
        'single_choice'
      end

      include TimestampableModel
    end
  end
end
