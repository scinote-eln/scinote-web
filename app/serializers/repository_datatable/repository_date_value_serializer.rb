# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateValueSerializer < RepositoryBaseValueSerializer
    def value
      data = {
        formatted: I18n.l(value_object.data, format: :full_date),
        datetime: value_object.data.strftime('%Y/%m/%d %H:%M')
      }

      if scope.dig(:options, :reminders_enabled)
        reminder_delta = scope[:column].metadata['reminder_delta']
        if !scope[:repository].is_a?(RepositorySnapshot) && reminder_delta
          data[:reminder] = DateTime.now + reminder_delta.to_i.seconds >= value_object.data
        end
      end

      data
    end
  end
end
