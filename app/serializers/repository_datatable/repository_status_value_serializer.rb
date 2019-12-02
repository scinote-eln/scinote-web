# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStatusValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      {
        id: object.repository_status_value.repository_status_item.id,
        icon: object.repository_status_value.repository_status_item.icon,
        status: object.repository_status_value.repository_status_item.status
      }
    end
  end
end
