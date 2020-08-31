# frozen_string_literal: true

module Api
  module V1
    class RepositoryDateValueSerializer < ActiveModel::Serializer
      attribute :formatted, key: :date
    end
  end
end
