# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateTimeRangeValueSerializer < RepositoryBaseValueSerializer
    def value
      {
        start_time: {
          formatted: I18n.l(object.start_time, format: :full_with_comma),
          date_formatted: I18n.l(object.start_time, format: :full_date),
          time_formatted: I18n.l(object.start_time, format: :time),
          datetime: object.start_time.strftime('%Y/%m/%d %H:%M')
        },
        end_time: {
          formatted: I18n.l(object.end_time, format: :full_with_comma),
          date_formatted: I18n.l(object.end_time, format: :full_date),
          time_formatted: I18n.l(object.end_time, format: :time),
          datetime: object.end_time.strftime('%Y/%m/%d %H:%M')
        }
      }
    end
  end
end
