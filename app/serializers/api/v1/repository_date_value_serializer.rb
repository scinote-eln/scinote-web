# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateValueSerializer < ActiveModel::Serializer
<<<<<<< HEAD
<<<<<<< HEAD
      attribute :date

      include TimestampableModel

      def date
        object.data.to_date
      end
=======
      attribute :formatted, key: :date
>>>>>>> Pulled latest release
=======
      attribute :date

      include TimestampableModel

      def date
        object.data.to_date
      end
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    end
  end
end
