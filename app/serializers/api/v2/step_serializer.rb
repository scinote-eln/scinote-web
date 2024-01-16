# frozen_string_literal: true

module Api
  module V2
    class StepSerializer < ActiveModel::Serializer
      include ApplicationHelper
      include ActionView::Helpers::TextHelper
      include InputSanitizeHelper

      type :steps
      attributes :id, :name, :position, :completed
      attribute :completed_on, if: -> { object.completed? }
      belongs_to :user, serializer: Api::V1::UserSerializer
      belongs_to :protocol, serializer: Api::V1::ProtocolSerializer
      has_many :assets, serializer: AssetSerializer
      has_many :checklists, serializer: Api::V1::ChecklistSerializer
      has_many :tables, serializer: Api::V1::TableSerializer
      has_many :step_texts, serializer: Api::V1::StepTextSerializer
      has_many :step_comments, key: :comments, serializer: Api::V1::CommentSerializer
      has_many :step_orderable_elements, key: :step_elements, serializer: Api::V1::StepOrderableElementSerializer

      include TimestampableModel
    end
  end
end
