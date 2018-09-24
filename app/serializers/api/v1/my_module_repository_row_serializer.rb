# frozen_string_literal: true

module Api
  module V1
    class MyModuleRepositoryRowSerializer < ActiveModel::Serializer
      type :task_inventory_rows
      attribute :repository_row_id, key: :inventory_row_id
      attribute :my_module_id, key: :task_id
      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
