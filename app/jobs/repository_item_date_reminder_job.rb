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
      .joins(repository_cell: { repository_column: :repository })
      .where(notification_sent: false, repositories: { type: 'Repository' })
      .where('repository_date_time_values.updated_at >= ?', 2.days.ago)
      .where( # date(time) values that are within the reminder range
        "data <= " \
        "(?::timestamp + CAST(((repository_columns.metadata->>'reminder_unit')::int * " \
        "(repository_columns.metadata->>'reminder_value')::int) || ' seconds' AS Interval))",
        comparison_value
      ).find_each do |value|
        RepositoryItemDateNotification
          .send_notifications({ "#{value.class.name.underscore}_id": value.id,
                                repository_row_id: value.repository_cell.repository_row_id,
                                repository_column_id: value.repository_cell.repository_column_id })
      end
  end
end
