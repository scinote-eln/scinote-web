# frozen_string_literal: true

module Api
  module V1
    class ReportSerializer < ActiveModel::Serializer
      type :reports
      attributes :id, :name, :description, :project_id

      belongs_to :project, serializer: ProjectSerializer
    end
  end
end
