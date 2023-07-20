# frozen_string_literal: true

module Api
  module V1
    class StepTextSerializer < ActiveModel::Serializer
      type :step_texts
      attributes :id, :text, :position

      include TimestampableModel

      def contents
        object.text&.force_encoding(Encoding::UTF_8)
      end

      def position
        object&.step_orderable_element&.position
      end
    end
  end
end
