# frozen_string_literal: true

module Api
  module V1
    class RepositoryTimeValueSerializer < ActiveModel::Serializer
      attribute :time

      include TimestampableModel

      def time
        object.data.strftime('%H:%M:%S.%3NZ')
      end
    end
  end
end
