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
      .where(notification_sent: false)
      .where('data <= ?', comparison_value)
      .joins(repository_cell: { repository_column: :repository })
      .where(repositories: { type: 'Repository' })
      .find_each do |value|
        RepositoryItemDateNotification
          .send_notifications({ "#{value.class.name.underscore}_id": value.id,
                                repository_row_id: value.repository_cell.repository_row_id,
                                repository_column_id: value.repository_cell.repository_column_id })
      end
  end
end
