# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateValueSerializer < RepositoryBaseValueSerializer
    def value
      data = {
        formatted: I18n.l(value_object.data, format: :full_date),
        datetime: value_object.data.strftime('%Y/%m/%d %H:%M')
      }

      if scope.dig(:options, :reminders_enabled) &&
         !scope[:repository].is_a?(RepositorySnapshot) &&
         scope[:column].reminder_value.present? &&
         scope[:column].reminder_unit.present?
        reminder_delta = scope[:column].reminder_value.to_i * scope[:column].reminder_unit.to_i
        data[:reminder] = reminder_delta + DateTime.now.to_i >= value_object.data.to_i
        data[:reminder_message] = scope[:column].reminder_message
      end

      data
    end
  end
end
