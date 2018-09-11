# frozen_string_literal: true

module Api
  module V1
    class UserProjectSerializer < ActiveModel::Serializer
      type :user_projects
      attributes :id, :role, :user_id, :project_id, :created_at, :updated_at,
                 :assigned_by_id

      belongs_to :project, serializer: ProjectSerializer
    end
  end
end
