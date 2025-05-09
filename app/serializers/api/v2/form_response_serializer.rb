# frozen_string_literal: true

module Api
  module V2
    class FormResponseSerializer < ActiveModel::Serializer
      type :form_responses
      attributes :id, :position, :status

      belongs_to :form, serializer: Api::V2::FormSerializer
      belongs_to :created_by, serializer: Api::V1::UserSerializer
      belongs_to :submitted_by, serializer: Api::V1::UserSerializer
      has_many :form_field_values, namespace: Api::V2

      include TimestampableModel

      def form_field_values
        object.form_field_values.latest
      end

      def position
        object&.step_orderable_element&.position
      end
    end
  end
end
