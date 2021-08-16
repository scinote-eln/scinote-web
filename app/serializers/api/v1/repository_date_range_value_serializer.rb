# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateRangeValueSerializer < ActiveModel::Serializer
<<<<<<< HEAD
<<<<<<< HEAD
      attribute :date_range

      include TimestampableModel

=======
      attribute :date_range

>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
      def date_range
        {
          from: object.start_time.to_date,
          to: object.end_time.to_date
        }
      end
<<<<<<< HEAD
=======
      attribute :formatted, key: :date_range
>>>>>>> Pulled latest release
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    end
  end
end
