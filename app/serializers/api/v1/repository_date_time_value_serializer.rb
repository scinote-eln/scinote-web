# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateTimeValueSerializer < ActiveModel::Serializer
<<<<<<< HEAD
      attribute :date_time

      include TimestampableModel

      def date_time
        object.data
      end
=======
      attribute :formatted, key: :date_time
>>>>>>> Pulled latest release
    end
  end
end
