# frozen_string_literal: true

module Api
  module V1
    class MyModuleRepositoryRowSerializer < ActiveModel::Serializer
      type :task_inventory_rows
      attributes :id, :repository_row_id, :my_module_id, :assigned_by_id,
                 :created_at, :updated_at
      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
