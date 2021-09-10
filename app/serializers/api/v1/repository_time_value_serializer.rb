# frozen_string_literal: true

module Api
  module V1
    class RepositoryTimeValueSerializer < ActiveModel::Serializer
<<<<<<< HEAD
<<<<<<< HEAD
      attribute :time

      include TimestampableModel

      def time
        object.data.strftime('%H:%M:%S.%3NZ')
      end
=======
      attribute :formatted, key: :time
>>>>>>> Pulled latest release
=======
      attribute :time

      include TimestampableModel

      def time
        object.data.strftime('%H:%M:%S.%3NZ')
      end
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    end
  end
end
