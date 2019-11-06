# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryListValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      object.value.data
    end
  end
end
