# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryTextValueSerializer < RepositoryBaseValueSerializer
    def value
      object.repository_text_value.data
    end
  end
end
