# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateTimeValueSerializer < RepositoryBaseValueSerializer
    def value
      data = {
        formatted: I18n.l(object.data, format: :full_with_comma),
        date_formatted: I18n.l(object.data, format: :full_date),
        time_formatted: I18n.l(object.data, format: :time),
        datetime: object.data.strftime('%Y/%m/%d %H:%M')
      }

      reminder_delta = scope[:column].metadata['reminder_delta']
      data[:reminder] = reminder_delta.to_i + DateTime.now.to_i >= object.data.to_i if reminder_delta

      data
    end
  end
end
