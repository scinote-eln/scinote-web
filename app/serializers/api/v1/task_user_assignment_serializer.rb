# frozen_string_literal: true

module Api
  module V1
    class TaskUserAssignmentSerializer < ActiveModel::Serializer
      include UserRolesHelper

      type :task_user_assignments
      attributes :id, :role

      belongs_to :user, serializer: UserSerializer

      def role
        # TODO: sync about the role solution
        legacy_user_role_parser(object.user_role.name)
      end
    end
  end
end
