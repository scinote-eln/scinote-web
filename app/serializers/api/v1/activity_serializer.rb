# frozen_string_literal: true

module Api
  module V1
    class ActivitySerializer < ActiveModel::Serializer
      type :activities
      attributes :id, :my_module_id, :user_id, :type_of, :message, :created_at,
                 :updated_at, :project_id, :experiment_id
      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
