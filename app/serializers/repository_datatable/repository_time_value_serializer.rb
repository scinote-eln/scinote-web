# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryTimeValueSerializer < RepositoryBaseValueSerializer
    def value
      {
        formatted: I18n.l(value_object.data, format: :time),
        datetime: value_object.data.strftime('%Y/%m/%d %H:%M')
      }
    end
  end
end
