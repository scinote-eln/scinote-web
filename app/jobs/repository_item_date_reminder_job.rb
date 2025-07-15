# frozen_string_literal: true

class RepositoryItemDateReminderJob < ApplicationJob
  BUFFER_DAYS = 2

  queue_as :default

  def perform
    NewRelic::Agent.ignore_transaction
    process_repository_values(RepositoryDateTimeValue, DateTime.current)
    process_repository_values(RepositoryDateValue, Date.current)
  end

  private

  def repository_values_due(model, comparison_value)
    model
      .joins(repository_cell: [:repository_row, { repository_column: :repository }])
      .where(
        notification_sent: false,
        repositories: { type: 'Repository', archived: false },
        repository_rows: { archived: false }
      ).where( # date(time) values that are within the reminder range including buffer
        "(data > :comparison_cutoff) AND " \
        "data <= (:comparison_value::timestamp + CAST(((repository_columns.metadata->>'reminder_unit')::int * " \
        "(repository_columns.metadata->>'reminder_value')::int) || ' seconds' AS Interval))",
        comparison_cutoff: comparison_value - BUFFER_DAYS.days,
        comparison_value: comparison_value
      )
  end

  def process_repository_values(model, comparison_value)
    repository_values_due(model, comparison_value).find_each do |value|
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
