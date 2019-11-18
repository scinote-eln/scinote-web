# frozen_string_literal: true

module Api
  module V1
    class ProtocolSerializer < ActiveModel::Serializer
      type :protocols
      attributes :id, :name, :authors, :description, :protocol_type
      has_many :protocol_keywords,
               key: :keywords,
               serializer: ProtocolKeywordSerializer,
               class_name: 'ProtocolKeyword',
               unless: -> { object.protocol_keywords.empty? }
      has_many :steps, serializer: StepSerializer, if: -> { object.steps.any? }
      belongs_to :parent, serializer: ProtocolSerializer, if: -> { object.parent.present? }
    end
  end
end
