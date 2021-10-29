# frozen_string_literal: true

module Api
  module V1
    class ExperimentUserAssignmentSerializer < ActiveModel::Serializer
      type :experiment_user_assignments
      attributes :id

      belongs_to :user, serializer: UserSerializer
      belongs_to :user_role, serializer: UserRoleSerializer
    end
  end
end
