# frozen_string_literal: true

module Api
  module V1
    class TaskUserAssignmentSerializer < ActiveModel::Serializer
      type :task_user_assignments
      attributes :id

      belongs_to :user, serializer: UserSerializer
      belongs_to :user_role, serializer: UserRoleSerializer
    end
  end
end
