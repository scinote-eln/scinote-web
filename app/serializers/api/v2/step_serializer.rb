# frozen_string_literal: true

module Api
  module V2
    class StepSerializer < ActiveModel::Serializer
      include ApplicationHelper
      include ActionView::Helpers::TextHelper
      include InputSanitizeHelper

      type :steps
      attributes :id, :name, :position, :completed, :skipped_at, :archived
      attribute :completed_on, if: -> { object.completed? }
      belongs_to :user, serializer: Api::V1::UserSerializer
      belongs_to :protocol, serializer: Api::V1::ProtocolSerializer
      has_many :assets, serializer: AssetSerializer do
        object.archived? ? object.assets : object.assets.active
      end
      has_many :checklists, serializer: Api::V1::ChecklistSerializer do
        object.archived? ? object.checklists : object.checklists.active
      end

      has_many :tables, serializer: Api::V1::TableSerializer do
        object.archived? ? object.tables : object.tables.active
      end

      has_many :step_texts, serializer: Api::V1::StepTextSerializer do
        object.archived? ? object.step_texts : object.step_texts.active
      end

      has_many :step_comments, key: :comments, serializer: Api::V1::CommentSerializer
      has_many :form_responses, serializer: Api::V2::FormResponseSerializer do
        object.archived? ? object.form_responses : object.form_responses.active
      end
      has_many :step_orderable_elements, key: :step_elements, serializer: Api::V2::StepOrderableElementSerializer

      include TimestampableModel
    end
  end
end
