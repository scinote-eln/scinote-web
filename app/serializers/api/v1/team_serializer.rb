# frozen_string_literal: true

module Api
  module V1
    class TeamSerializer < ActiveModel::Serializer
      attributes :id, :name, :description, :space_taken
      belongs_to :created_by, serializer: UserSerializer
    end
  end
end
