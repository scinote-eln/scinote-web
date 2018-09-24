# frozen_string_literal: true

module Api
  module V1
    class ResultSerializer < ActiveModel::Serializer
      type :results
      attributes :id, :name, :user_id, :archived, :result_text,
                 :result_table, :result_asset
      attribute :my_module_id, key: :task_id

      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
