# frozen_string_literal: true

module Api
  module V1
    class MyModuleTagSerializer < ActiveModel::Serializer
      type :task_tags
      attributes :id, :tag_id
      attribute :my_module_id, key: :task_id

      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
