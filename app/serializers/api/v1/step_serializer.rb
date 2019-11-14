# frozen_string_literal: true

module Api
  module V1
    class StepSerializer < ActiveModel::Serializer
      type :steps
      attributes :id, :name, :description, :position, :completed
      attribute :completed_on, if: :completed?
      belongs_to :protocol, serializer: ProtocolSerializer
      has_many :assets, serializer: AssetSerializer

      def completed?
        object.completed
      end
    end
  end
end
