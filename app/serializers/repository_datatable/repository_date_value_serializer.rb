# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateValueSerializer < RepositoryBaseValueSerializer
    def value
      data = {
        formatted: I18n.l(object.data, format: :full_date),
        datetime: object.data.strftime('%Y/%m/%d %H:%M')
      }

      reminder_delta = scope[:column].metadata['reminder_delta']
      data[:reminder] = DateTime.now.to_date + reminder_delta.to_i.seconds >= object.data if reminder_delta

      data
    end
  end
end
