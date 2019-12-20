# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryChecklistValueSerializer < RepositoryBaseValueSerializer
    def value
      object.data
    end
  end
end
