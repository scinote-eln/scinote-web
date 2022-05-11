# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateValueSerializer < RepositoryBaseValueSerializer
    def value
      data = {
        formatted: I18n.l(object.data, format: :full_date),
        datetime: object.data.strftime('%Y/%m/%d %H:%M')
      }

      if RepositoryBase.reminders_enabled?
        reminder_delta = scope[:column].metadata['reminder_delta']
        if !scope[:repository].is_a?(RepositorySnapshot) && reminder_delta
          data[:reminder] = DateTime.now + reminder_delta.to_i.seconds >= object.data
        end
      end

      data
    end
  end
end
