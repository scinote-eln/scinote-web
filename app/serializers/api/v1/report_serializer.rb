# frozen_string_literal: true

module Api
  module V1
    class ReportSerializer < ActiveModel::Serializer
      type :reports
      attributes :id, :name, :description, :project_id, :user_id, :created_at,
                 :updated_at, :last_modified_by_id, :team_id

      belongs_to :project, serializer: ProjectSerializer
    end
  end
end
