# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateTimeValueSerializer < ActiveModel::Serializer
      attribute :formatted, key: :date_time
    end
  end
end
