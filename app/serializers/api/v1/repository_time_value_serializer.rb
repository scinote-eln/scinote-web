# frozen_string_literal: true

module Api
  module V1
    class RepositoryTimeValueSerializer < ActiveModel::Serializer
      attribute :formatted, key: :time
    end
  end
end
