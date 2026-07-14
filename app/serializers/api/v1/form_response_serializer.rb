# frozen_string_literal: true

module Api
  module V1
    class FormResponseSerializer < ActiveModel::Serializer
      type :form_responses
      attributes :id, :position, :locked

      include TimestampableModel

      def position
        object&.step_orderable_element&.position
      end

      def locked
        object.locked || object.step.locked
      end
    end
  end
end
