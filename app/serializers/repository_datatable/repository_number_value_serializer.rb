# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryNumberValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      object.repository_number_value.data
    end
  end
end
