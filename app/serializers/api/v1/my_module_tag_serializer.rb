# frozen_string_literal: true

module Api
  module V1
    class MyModuleTagSerializer < ActiveModel::Serializer
      type :task_tags
      attributes :id, :my_module_id, :tag_id, :created_by_id
      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
