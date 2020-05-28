# frozen_string_literal: true

module Api
  module V1
    class RepositoryTimeRangeValueSerializer < ActiveModel::Serializer
      attribute :formatted, key: :time_range
    end
  end
end
