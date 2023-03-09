# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateRangeValueSerializer < RepositoryBaseValueSerializer
    def value
      {
        start_time: {
          formatted: I18n.l(value_object.start_time, format: :full_date),
          datetime: value_object.start_time.strftime('%Y/%m/%d %H:%M')
        },
        end_time: {
          formatted: I18n.l(value_object.end_time, format: :full_date),
          datetime: value_object.end_time.strftime('%Y/%m/%d %H:%M')
        }
      }
    end
  end
end
