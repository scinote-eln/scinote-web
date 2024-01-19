# frozen_string_literal: true

module Api
  module V2
    class ResultSerializer < ActiveModel::Serializer
      type :results
      attributes :name, :archived
      belongs_to :user, serializer: Api::V1::UserSerializer

      has_many :result_comments, key: :comments, serializer: Api::V1::CommentSerializer
      has_many :result_texts, key: :result_texts, serializer: ResultTextSerializer
      has_many :result_tables, key: :tables, serializer: ResultTableSerializer
      has_many :assets, serializer: AssetSerializer
      has_many :result_orderable_elements, key: :result_elements, serializer: ResultOrderableElementSerializer

      include TimestampableModel
    end
  end
end
