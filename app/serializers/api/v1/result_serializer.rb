# frozen_string_literal: true

module Api
  module V1
    class ResultSerializer < ActiveModel::Serializer
      type :results
      attributes :id, :name, :my_module_id, :user_id, :created_at, :updated_at,
                 :archived, :archived_on, :last_modified_by_id, :archived_by_id,
                 :restored_by_id, :restored_on, :result_text, :result_table,
                 :result_asset

      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
