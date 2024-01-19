# frozen_string_literal: true

class RepositoryItemDateReminderJob < ApplicationJob
  queue_as :default

  def perform
    process_repository_values(RepositoryDateTimeValue, DateTime.current)
    process_repository_values(RepositoryDateValue, Date.current)
  end

  private

  def process_repository_values(model, comparison_value)
    model
      .joins(repository_cell: [:repository_row, { repository_column: :repository }])
      .where(
        notification_sent: false,
        repositories: { type: 'Repository', archived: false },
        repository_rows: { archived: false }
      ).where('repository_date_time_values.updated_at >= ?', 2.days.ago)
      .where( # date(time) values that are within the reminder range
        "data <= " \
        "(?::timestamp + CAST(((repository_columns.metadata->>'reminder_unit')::int * " \
        "(repository_columns.metadata->>'reminder_value')::int) || ' seconds' AS Interval))",
        comparison_value
      ).find_each do |value|
        repository_row = RepositoryRow.find(value.repository_cell.repository_row_id)
        repository_column = RepositoryColumn.find(value.repository_cell.repository_column_id)

        RepositoryItemDateNotification
          .send_notifications({
                                "#{value.class.name.underscore}_id": value.id,
                                repository_row_id: repository_row.id,
                                repository_row_name: repository_row.name,
                                repository_column_id: repository_column.id,
                                repository_column_name: repository_column.name,
                                reminder_unit: repository_column.metadata['reminder_unit'],
                                reminder_value: repository_column.metadata['reminder_value']
                              })
      end
  end
end
