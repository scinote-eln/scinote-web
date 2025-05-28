# frozen_string_literal: true

module Api
  module V1
    class ExperimentSerializer < ActiveModel::Serializer
      type :experiments
      attributes :id, :name, :status, :description, :archived, :started_at, :completed_at, :due_date, :start_on
      attribute :metadata, if: -> { scope && scope[:metadata] == true }

      include TimestampableModel
    end
  end
end
