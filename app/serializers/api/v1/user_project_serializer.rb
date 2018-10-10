# frozen_string_literal: true

module Api
  module V1
    class UserProjectSerializer < ActiveModel::Serializer
      type :user_projects
      attributes :id, :role

      belongs_to :user, serializer: UserSerializer
    end
  end
end
