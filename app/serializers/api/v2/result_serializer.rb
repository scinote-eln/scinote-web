# frozen_string_literal: true

module Api
  module V2
    class ResultSerializer < ActiveModel::Serializer
      type :results
      attributes :name, :archived
      belongs_to :user, serializer: Api::V1::UserSerializer

      has_many :result_comments, key: :comments, serializer: Api::V1::CommentSerializer
      has_many :result_texts, key: :result_texts, serializer: ResultTextSerializer do
        object.archived? ? object.result_texts : object.result_texts.active
      end
      has_many :result_tables, key: :tables, serializer: ResultTableSerializer do
        object.archived? ? object.result_tables : object.result_tables.active
      end
      has_many :assets, serializer: AssetSerializer do
        object.archived? ? object.assets : object.assets.active
      end
      has_many :result_orderable_elements, key: :result_elements, serializer: ResultOrderableElementSerializer do
        object.archived? ? object.result_orderable_elements : object.result_orderable_elements.active
      end

      include TimestampableModel
    end
  end
end
