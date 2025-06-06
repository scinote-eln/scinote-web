# frozen_string_literal: true

module Api
  module V1
    class ExperimentSerializer < ActiveModel::Serializer
      type :experiments
      attributes :id, :name, :status, :description, :archived, :started_at, :done_at, :due_date, :start_date
      attribute :metadata, if: -> { scope && scope[:metadata] == true }

      include TimestampableModel
    end
  end
end
