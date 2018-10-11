# frozen_string_literal: true

module Api
  module V1
    class ReportSerializer < ActiveModel::Serializer
      type :reports
      attributes :id, :name, :description
      belongs_to :user, serializer: UserSerializer
      belongs_to :project, serializer: ProjectSerializer,
                           unless: -> { instance_options[:hide_project] }
    end
  end
end
