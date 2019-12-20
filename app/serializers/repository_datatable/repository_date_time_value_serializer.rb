# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateTimeValueSerializer < RepositoryBaseValueSerializer
    def value
      {
        formatted: I18n.l(object.data, format: :full_with_comma),
        date_formatted: I18n.l(object.data, format: :full_date),
        time_formatted: I18n.l(object.data, format: :time),
        datetime: object.data.strftime('%Y/%m/%d %H:%M')
      }
    end
  end
end
