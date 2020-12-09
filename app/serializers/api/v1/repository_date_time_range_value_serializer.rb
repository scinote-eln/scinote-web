# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateTimeRangeValueSerializer < ActiveModel::Serializer
<<<<<<< HEAD
      attribute :date_time_range

      include TimestampableModel

      def date_time_range
        {
          from: object.start_time,
          to: object.end_time
        }
      end
=======
      attribute :formatted, key: :date_time_range
>>>>>>> Pulled latest release
    end
  end
end
