# frozen_string_literal: true

module Api
  module V1
    class ExperimentSerializer < ActiveModel::Serializer
      type :experiments
      attributes :id, :name, :description, :archived
      attribute :metadata, if: -> { scope && scope[:metadata] == true }

      include TimestampableModel
    end
  end
end
