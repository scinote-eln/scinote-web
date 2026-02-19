# frozen_string_literal: true

module Api
  module V2
    class TeamAssignmentSerializer < ActiveModel::Serializer
      type :team_assignments
      belongs_to :user_role, serializer: Api::V1::UserRoleSerializer
      belongs_to :team, serializer: Api::V1::TeamSerializer

      include TimestampableModel
    end
  end
end
