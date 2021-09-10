# frozen_string_literal: true

module Api
  module V1
    class RepositoryTimeRangeValueSerializer < ActiveModel::Serializer
      attribute :time_range

      include TimestampableModel

      def time_range
        {
          from: object.start_time.strftime('%H:%M:%S.%3NZ'),
          to: object.start_time.strftime('%H:%M:%S.%3NZ')
        }
      end
    end
  end
end
