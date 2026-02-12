# frozen_string_literal: true

module Api
  module V2
    class UserGroupSerializer < ActiveModel::Serializer
      type :user_groups
      attributes :name
      belongs_to :team, serializer: Api::V1::TeamSerializer
      has_many :users, serializer: Api::V1::UserSerializer

      include TimestampableModel
    end
  end
end
