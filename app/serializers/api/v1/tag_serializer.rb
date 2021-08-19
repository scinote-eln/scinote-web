# frozen_string_literal: true

module Api
  module V1
    class TagSerializer < ActiveModel::Serializer
      type :tags
      attributes :id, :name, :color

      include TimestampableModel
    end
  end
end
