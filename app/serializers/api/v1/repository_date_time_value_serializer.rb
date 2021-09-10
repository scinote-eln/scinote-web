# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateTimeValueSerializer < ActiveModel::Serializer
<<<<<<< HEAD
<<<<<<< HEAD
      attribute :date_time

      include TimestampableModel

      def date_time
        object.data
      end
=======
      attribute :formatted, key: :date_time
>>>>>>> Pulled latest release
=======
      attribute :date_time

      include TimestampableModel

      def date_time
        object.data
      end
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    end
  end
end
