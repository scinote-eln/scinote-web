# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryTextValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      object.repository_text_value.data
    end
  end
end
