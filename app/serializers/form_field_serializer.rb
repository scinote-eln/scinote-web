# frozen_string_literal: true

class FormFieldSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :updated_at, :type, :required, :allow_not_applicable, :uid, :position

  def type
    object.data[:type]
  end
end
