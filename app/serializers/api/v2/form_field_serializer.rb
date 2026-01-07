# frozen_string_literal: true

module Api
  module V2
    class FormFieldSerializer < ActiveModel::Serializer
      type :form_fields
      attributes :id, :name, :position, :data, :required, :allow_not_applicable

      include TimestampableModel
    end
  end
end
