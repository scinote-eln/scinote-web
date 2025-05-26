# frozen_string_literal: true

class AddDueDateReminderNotificationColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :due_date_notification_sent, :boolean, default: false, null: false
    add_column :experiments, :due_date_notification_sent, :boolean, default: false, null: false
  end
end
