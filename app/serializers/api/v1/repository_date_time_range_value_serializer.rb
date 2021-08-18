# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateTimeRangeValueSerializer < ActiveModel::Serializer
      attribute :date_time_range

      include TimestampableModel

      def date_time_range
        {
          from: object.start_time,
          to: object.end_time
        }
      end
    end
  end
end
