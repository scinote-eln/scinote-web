# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateValueSerializer < RepositoryBaseValueSerializer
    def value
      I18n.l(object.data, format: :full_date)
    end
  end
end
