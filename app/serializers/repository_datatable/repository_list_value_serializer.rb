# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryListValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      object.repository_list_value.data
    end
  end
end
