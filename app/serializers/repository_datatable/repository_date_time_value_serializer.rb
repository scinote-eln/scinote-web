# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateTimeValueSerializer < RepositoryBaseValueSerializer
    def value
      I18n.l(object.data, format: :full_with_comma)
    end
  end
end
