# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateValueSerializer < ActiveModel::Serializer
<<<<<<< HEAD
      attribute :date

      include TimestampableModel

      def date
        object.data.to_date
      end
=======
      attribute :formatted, key: :date
>>>>>>> Pulled latest release
    end
  end
end
