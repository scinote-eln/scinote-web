# frozen_string_literal: true

module Api
  module V1
    class UserRoleSerializer < ActiveModel::Serializer
      attributes :id, :name, :permissions
    end
  end
end
