# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryTimeValueSerializer < RepositoryBaseValueSerializer
    def value
      I18n.l(object.data, format: :time)
    end
  end
end
