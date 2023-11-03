# frozen_string_literal: true

class AddTaskDueDateReminderNotification < ActiveRecord::Migration[7.0]
  def change
    add_column :my_modules, :due_date_notification_sent, :boolean, default: false
  end
end
