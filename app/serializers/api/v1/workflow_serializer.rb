# frozen_string_literal: true

module Api
  module V1
    class WorkflowSerializer < ActiveModel::Serializer
      type :workflows
      attributes :id, :name, :description, :visibility, :team_id

      include TimestampableModel
    end
  end
end
