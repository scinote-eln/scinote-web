# frozen_string_literal: true

module Api
  module V1
    class TaskAssignmentSerializer < ActiveModel::Serializer
      type :task_assignments
      attributes :id
      belongs_to :user, serializer: UserSerializer
      belongs_to :my_module, key: :tasks,
                             serializer: TaskSerializer

      include TimestampableModel
    end
  end
end
