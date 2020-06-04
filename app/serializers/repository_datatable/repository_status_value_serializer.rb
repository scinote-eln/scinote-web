# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStatusValueSerializer < RepositoryBaseValueSerializer
    include InputSanitizeHelper
    def value
      {
        id: object.repository_status_item.id,
        icon: object.repository_status_item.icon,
        status: escape_input(object.repository_status_item.status)
      }
    end
  end
end
