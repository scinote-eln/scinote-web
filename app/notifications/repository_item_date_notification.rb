# frozen_string_literal: true

class RepositoryItemDateNotification < BaseNotification
  def message
    unit = human_readable_unit(column.metadata['reminder_unit'], column.metadata['reminder_value'])
    I18n.t(
      'notifications.content.item_date_reminder.message_html',
      repository_row_name: subject.name,
      value: column.metadata['reminder_value'],
      units: unit
    )
  end

  def self.subtype
    :item_date_reminder
  end

  def title; end

  def subject
    RepositoryRow.find(params[:repository_row_id])
  end

  def column
    RepositoryColumn.find(params[:repository_column_id])
  end

  after_deliver do
    if params[:repository_date_time_value_id]
      RepositoryDateTimeValue.find(params[:repository_date_time_value_id]).update(notification_sent: true)
    elsif params[:repository_date_value_id]
      RepositoryDateValue.find(params[:repository_date_value_id]).update(notification_sent: true)
    end
  end

  private

  def human_readable_unit(seconds, value)
    units_hash = {
      '2419200' => 'month',
      '604800' => 'week',
      '86400' => 'day'
    }

    base_unit = units_hash.fetch(seconds) do
      raise ArgumentError, "Unrecognized time unit for seconds value: #{seconds}"
    end

    value.to_i > 1 ? base_unit.pluralize : base_unit
  end
end
