# frozen_string_literal: true

module Api
  module V1
    class ResultSerializer < ActiveModel::Serializer
      type :results
      attributes :name, :archived
      belongs_to :user, serializer: UserSerializer
      has_one :result_text, key: :text,
                            serializer: ResultTextSerializer,
                            class_name: 'ResultText' do |serializer|
                              serializer.object.result_texts.first
                            end
      has_one :result_table, key: :table,
                             serializer: ResultTableSerializer,
                             class_name: 'ResultTable' do |serializer|
                               serializer.object.result_tables.first
                             end
      has_one :result_asset, key: :file,
                             serializer: ResultAssetSerializer,
                             class_name: 'ResultAsset' do |serializer|
                               serializer.object.result_assets.first
                             end
      has_many :result_comments, key: :comments, serializer: CommentSerializer
      has_many :result_orderable_elements, key: :result_elements, serializer: ResultOrderableElementSerializer

      include TimestampableModel
    end
  end
end
