# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateTimeRangeValueSerializer < ActiveModel::Serializer
<<<<<<< HEAD
<<<<<<< HEAD
      attribute :date_time_range

      include TimestampableModel

=======
      attribute :date_time_range

>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
      def date_time_range
        {
          from: object.start_time,
          to: object.end_time
        }
      end
<<<<<<< HEAD
=======
      attribute :formatted, key: :date_time_range
>>>>>>> Pulled latest release
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    end
  end
end
