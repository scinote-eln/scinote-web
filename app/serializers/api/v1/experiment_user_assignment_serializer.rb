# frozen_string_literal: true

module Api
  module V1
    class ExperimentUserAssignmentSerializer < ActiveModel::Serializer
      type :experiment_user_assignments
      attributes :id, :role

      belongs_to :user, serializer: UserSerializer
      belongs_to :experiment, serializer: ExperimentSerializer
    end
  end
end
