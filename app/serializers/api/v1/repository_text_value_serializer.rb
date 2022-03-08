# frozen_string_literal: true

module Api
  module V1
    class RepositoryTextValueSerializer < ActiveModel::Serializer
      attribute :formatted, key: :text
    end
  end
end
