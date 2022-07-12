# frozen_string_literal: true

module Api
  module V1
    class StepTextSerializer < ActiveModel::Serializer
      type :tables
      attributes :id, :text

      include TimestampableModel

      def contents
        object.text&.force_encoding(Encoding::UTF_8)
      end
    end
  end
end
