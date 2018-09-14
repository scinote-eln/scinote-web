# frozen_string_literal: true

module Api
  module V1
    class ExperimentSerializer < ActiveModel::Serializer
      type :experiments
      attributes :id, :name, :description, :archived
    end
  end
end
