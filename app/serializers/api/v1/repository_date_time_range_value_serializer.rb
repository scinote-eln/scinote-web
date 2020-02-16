# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateTimeRangeValueSerializer < ActiveModel::Serializer
      attribute :formatted, key: :date_time_range
    end
  end
end
