# frozen_string_literal: true

module Api
  module V1
    class ActivitySerializer < ActiveModel::Serializer
      type :activities

      attributes :id, :user_id, :type_of, :message,
                 :project_id, :experiment_id
      attribute :my_module_id, key: :task_id
      belongs_to :my_module, serializer: MyModuleSerializer
      belongs_to :experiment, serializer: ExperimentSerializer
      belongs_to :project, serializer: ProjectSerializer
    end
  end
end
