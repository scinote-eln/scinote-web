json.reminders do
  json.array! @reminder_cells.each do |reminder|
    json.type reminder.value_type
    if can_manage_repository_rows?(reminder.repository_row.repository)
      json.clear_all_url repository_repository_row_repository_cell_hide_reminders_path(reminder.repository_row.repository, reminder.repository_row, reminder)
    end
    json.clear_url repository_repository_row_repository_cell_hide_reminder_path(reminder.repository_row.repository, reminder.repository_row, reminder)
    if reminder.value_type == 'RepositoryStockValue'
      json.empty reminder.value.amount <= 0
      json.stock_formatted reminder.value.formatted
    elsif reminder.value_type == 'RepositoryDateTimeValueBase'
      json.expired reminder.value.data < Time.now.utc
      json.expiration_date_formatted pluralize(((reminder.value.data - Time.now.utc)/1.day).ceil, t('repository_row.reminder.day'))
      if reminder.repository_column.metadata["reminder_message"].present?
        json.message reminder.repository_column.metadata["reminder_message"]
      end
    end
  end
end
