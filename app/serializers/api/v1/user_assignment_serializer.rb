# frozen_string_literal: true

module Api
  module V1
    class UserAssignmentSerializer < ActiveModel::Serializer
      type :user_assignments
      attributes :id
      belongs_to :user_role, serializer: UserRoleSerializer
      belongs_to :user, serializer: UserSerializer
      belongs_to :assignable

      class << self
        def serializer_for(model, options)
          return TaskSerializer if model.instance_of? MyModule
          return ExperimentSerializer if model.instance_of? Experiment
          return ProjectSerializer if model.instance_of? Project

          super
        end
      end

      include TimestampableModel
    end
  end
end
