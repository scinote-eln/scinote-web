# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateValueSerializer < ActiveModel::Serializer
      attribute :date

      include TimestampableModel

      def date
        Time.use_zone('UTC') do # all Date values are stored as UTC DateTime
          object.data.to_date
        end
      end
    end
  end
end
