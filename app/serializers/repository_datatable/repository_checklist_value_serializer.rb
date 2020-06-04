# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryChecklistValueSerializer < RepositoryBaseValueSerializer
    include InputSanitizeHelper
    def value
      object.data.each { |i| i[:label] = escape_input(i[:label]) }
    end
  end
end
