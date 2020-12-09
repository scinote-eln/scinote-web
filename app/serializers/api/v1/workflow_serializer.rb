# frozen_string_literal: true

module Api
  module V1
    class WorkflowSerializer < ActiveModel::Serializer
      type :workflows
<<<<<<< HEAD
      attributes :id, :name, :description, :visibility, :team_id

      include TimestampableModel
=======

      attributes :id, :name, :description, :visibility, :team_id
>>>>>>> Pulled latest release
    end
  end
end
