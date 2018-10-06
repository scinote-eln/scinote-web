# frozen_string_literal: true

module Api
  module V1
    class UserMyModuleSerializer < ActiveModel::Serializer
      type :user_tasks
      attributes :id, :user_id
      attribute :my_module_id, key: :task_id

      belongs_to :my_module, serializer: TaskSerializer
    end
  end
end
