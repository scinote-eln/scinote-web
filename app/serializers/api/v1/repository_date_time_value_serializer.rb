# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateTimeValueSerializer < ActiveModel::Serializer
      attribute :date_time

      include TimestampableModel

      def date_time
        object.data
      end
    end
  end
end
