# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateRangeValueSerializer < ActiveModel::Serializer
      attribute :formatted, key: :date_range
    end
  end
end
