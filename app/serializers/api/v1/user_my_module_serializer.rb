# frozen_string_literal: true

module Api
  module V1
    class UserMyModuleSerializer < ActiveModel::Serializer
      type :user_tasks
      attributes :id, :user_id, :my_module_id, :created_at,
                 :updated_at, :assigned_by_id
      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
