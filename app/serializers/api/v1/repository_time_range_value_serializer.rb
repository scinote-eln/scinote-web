# frozen_string_literal: true

module Api
  module V1
    class RepositoryTimeRangeValueSerializer < ActiveModel::Serializer
<<<<<<< HEAD
<<<<<<< HEAD
      attribute :time_range

      include TimestampableModel

=======
      attribute :time_range

>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
      def time_range
        {
          from: object.start_time.strftime('%H:%M:%S.%3NZ'),
          to: object.start_time.strftime('%H:%M:%S.%3NZ')
        }
      end
<<<<<<< HEAD
=======
      attribute :formatted, key: :time_range
>>>>>>> Pulled latest release
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    end
  end
end
