# frozen_string_literal: true

module Api
  module V1
    class RepositoryNumberValueSerializer < ActiveModel::Serializer
      attribute :data

      include TimestampableModel
    end
  end
end
