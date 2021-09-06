# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateValueSerializer < ActiveModel::Serializer
      attribute :date

      include TimestampableModel

      def date
        object.data.to_date
      end
    end
  end
end
