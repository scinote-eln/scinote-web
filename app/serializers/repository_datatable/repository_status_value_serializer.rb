# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStatusValueSerializer < RepositoryBaseValueSerializer
    include InputSanitizeHelper
    def value
      {
        id: value_object.repository_status_item.id,
        icon: value_object.repository_status_item.icon,
        status: escape_input(value_object.repository_status_item.status)
      }
    end
  end
end
