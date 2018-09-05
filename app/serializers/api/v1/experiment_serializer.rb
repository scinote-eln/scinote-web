# frozen_string_literal: true

module Api
  module V1
    class ExperimentSerializer < ActiveModel::Serializer
      type :experiment
      attributes :id, :name, :description
      has_many :my_modules
    end
  end
end
