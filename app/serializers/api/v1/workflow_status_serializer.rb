# frozen_string_literal: true

module Api
  module V1
    class WorkflowStatusSerializer < ActiveModel::Serializer
      type :workflow_statuses
      attributes :id, :name, :description, :color, :previous_status_id

      include TimestampableModel
    end
  end
end
