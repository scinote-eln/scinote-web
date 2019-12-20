# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStatusValueSerializer < RepositoryBaseValueSerializer
    def value
      {
        id: object.repository_status_item.id,
        icon: object.repository_status_item.icon,
        status: object.repository_status_item.status
      }
    end
  end
end
