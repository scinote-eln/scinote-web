# frozen_string_literal: true

module Api
  module V1
    class UserAssignmentSerializer < ActiveModel::Serializer
      type :user_assignments
      attributes :id
      belongs_to :user_role
      belongs_to :user
      belongs_to :assignable

      include TimestampableModel
    end
  end
end
