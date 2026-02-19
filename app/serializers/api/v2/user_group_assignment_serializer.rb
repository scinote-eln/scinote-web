# frozen_string_literal: true

module Api
  module V2
    class UserGroupAssignmentSerializer < ActiveModel::Serializer
      type :user_group_assignments
      belongs_to :user_role, serializer: Api::V1::UserRoleSerializer
      belongs_to :user_group, serializer: Api::V2::UserGroupSerializer

      include TimestampableModel
    end
  end
end
