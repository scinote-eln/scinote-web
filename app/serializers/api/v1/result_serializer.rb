# frozen_string_literal: true

module Api
  module V1
    class ResultSerializer < ActiveModel::Serializer
      type :results
      attributes :name, :archived
      belongs_to :user, serializer: UserSerializer
      has_one :result_text, key: :text,
                            serializer: ResultTextSerializer,
                            class_name: 'ResultText',
                            if: -> { object.is_text }
      has_one :result_table, key: :table,
                             serializer: ResultTableSerializer,
                             class_name: 'ResultTable',
                             if: -> { object.is_table }
      has_one :result_asset, key: :file,
                             serializer: ResultAssetSerializer,
                             class_name: 'ResultAsset',
                             if: -> { object.is_asset }
    end
  end
end
