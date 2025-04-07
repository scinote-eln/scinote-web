# frozen_string_literal: true

module Api
  module V2
    class FormSerializer < ActiveModel::Serializer
      type :forms
      attributes :id, :name, :description

      include TimestampableModel
    end
  end
end
