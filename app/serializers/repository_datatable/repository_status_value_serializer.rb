# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStatusValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      {
        icon: object.value.repository_status_item.icon,
        status: object.value.repository_status_item.status
      }
    end
  end
end
