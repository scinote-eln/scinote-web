# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryTextValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      object.value.data
    end
  end
end
