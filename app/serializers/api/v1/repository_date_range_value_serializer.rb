# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateRangeValueSerializer < ActiveModel::Serializer
      attribute :date_range

      include TimestampableModel

      def date_range
        {
          from: object.start_time.to_date,
          to: object.end_time.to_date
        }
      end
    end
  end
end
