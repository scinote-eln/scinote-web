# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryListValueSerializer < RepositoryBaseValueSerializer
    include InputSanitizeHelper
    def value
      {
        id: (object.repository_list_item&.id || ''),
        text: (escape_input(object.data) || '')
      }
    end
  end
end
