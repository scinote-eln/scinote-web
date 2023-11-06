# frozen_string_literal: true

class RepositoryItemDateNotification < BaseNotification
  def message
    I18n.t(
      'notifications.notification.item_date_reminder_html',
      repository_row_name: subject.name
    )
  end

  def self.subtype
    :item_date_reminder
  end

  def title; end

  def subject
    RepositoryRow.find(params[:repository_row_id])
  end

  after_deliver do
    RepositoryDateTimeValue.find(params[:date_time_value_id]).update(notification_sent: true)
  end
end
