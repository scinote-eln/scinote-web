# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryListValueSerializer < RepositoryBaseValueSerializer
    include InputSanitizeHelper
    def value
      {
        id: (value_object.repository_list_item&.id || ''),
        text: (escape_input(value_object.data) || '')
      }
    end
  end
end
