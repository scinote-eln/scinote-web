# frozen_string_literal: true

module Api
  module V1
    class WorkflowStatusSerializer < ActiveModel::Serializer
      type :workflow_statuses
<<<<<<< HEAD
      attributes :id, :name, :description, :color, :previous_status_id

      include TimestampableModel
=======

      attributes :id, :name, :description, :color, :previous_status_id
>>>>>>> Pulled latest release
    end
  end
end
