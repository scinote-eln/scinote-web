# frozen_string_literal: true

module Api
  module V1
    class ProjectUserAssignmentSerializer < ActiveModel::Serializer
      type :user_projects
      attributes :id

      belongs_to :user, serializer: UserSerializer
      belongs_to :user_role, serializer: UserRoleSerializer
    end
  end
end
