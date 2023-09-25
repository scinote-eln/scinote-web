# frozen_string_literal: true

module Api
  module V1
    class ResultSerializer < ActiveModel::Serializer
      type :results
      attributes :name, :archived, :result_text, :result_table, :result_asset
      belongs_to :user, serializer: UserSerializer
      has_many :result_comments, key: :comments, serializer: CommentSerializer
      has_many :result_orderable_elements, key: :result_elements, serializer: ResultOrderableElementSerializer
      has_many :assets, serializer: AssetSerializer

      include TimestampableModel

      def result_text
        Api::V1::ResultTextSerializer.new(object.result_texts.first).as_json if object.result_texts.any?
      end

      def result_table
        Api::V1::ResultTableSerializer.new(object.result_tables.first).as_json if object.result_tables.any?
      end

      def result_asset
        Api::V1::ResultAssetSerializer.new(object.result_assets.first).as_json if object.result_assets.any?
      end
    end
  end
end
