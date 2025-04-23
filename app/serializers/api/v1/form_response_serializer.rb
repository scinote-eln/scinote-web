# frozen_string_literal: true

module Api
  module V1
    class FormResponseSerializer < ActiveModel::Serializer
      type :form_responses
      attributes :id, :position

      include TimestampableModel

      def position
        object&.step_orderable_element&.position
      end
    end
  end
end
