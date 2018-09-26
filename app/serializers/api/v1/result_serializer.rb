# frozen_string_literal: true

module Api
  module V1
    class ResultSerializer < ActiveModel::Serializer
      type :results
      attributes :name, :user_id, :archived
      attribute :my_module_id, key: :task_id

      belongs_to :my_module, serializer: MyModuleSerializer
      has_one :result_asset, key: :asset,
                             serializer: ResultAssetSerializer,
                             class_name: 'ResultAsset',
                             if: -> { object.is_asset }
      has_one :result_table, key: :table,
                             serializer: ResultTableSerializer,
                             class_name: 'ResultTable',
                             if: -> { object.is_table }
      has_one :result_text, key: :text,
                            serializer: ResultTextSerializer,
                            class_name: 'ResultText',
                            if: -> { object.is_text }
    end
  end
end
