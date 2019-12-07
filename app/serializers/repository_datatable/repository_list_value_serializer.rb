# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryListValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      {
        id: object.repository_list_value.repository_list_item.id,
        text: object.repository_list_value.data
      }
    end
  end
end
