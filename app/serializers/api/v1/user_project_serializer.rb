# frozen_string_literal: true

module Api
  module V1
    class UserProjectSerializer < ActiveModel::Serializer
      type :user_projects
      attributes :id, :role, :user_id

      belongs_to :project, serializer: ProjectSerializer
    end
  end
end
