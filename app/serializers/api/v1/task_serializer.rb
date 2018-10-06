# frozen_string_literal: true

module Api
  module V1
    class TaskSerializer < ActiveModel::Serializer
      type :tasks
      attributes :id, :name, :due_date, :description, :state
      attribute :my_module_group_id, key: :task_group_id
      belongs_to :experiment, serializer: ExperimentSerializer
    end
  end
end
