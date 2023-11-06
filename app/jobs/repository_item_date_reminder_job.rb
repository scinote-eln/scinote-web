# frozen_string_literal: true

class RepositoryItemDateReminderJob < ApplicationJob
  queue_as :default

  def perform
    RepositoryDateTimeValue
      .where(notification_sent: false)
      .where('data <= ?', DateTime.current)
      .joins(repository_cell: { repository_column: :repository })
      .where(repositories: { type: 'Repository' })
      .find_each do |date_time_value|
      RepositoryItemDateNotification
        .send_notifications({ date_time_value_id: date_time_value.id,
                              repository_row_id: date_time_value.repository_cell.repository_row_id })
    end
  end
end
