# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryListValueSerializer < RepositoryBaseValueSerializer
    def value
      {
        id: (object.repository_list_item&.id || ''),
        text: (object.data || '')
      }
    end
  end
end
