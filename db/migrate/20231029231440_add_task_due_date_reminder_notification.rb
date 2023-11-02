class AddTaskDueDateReminderNotification < ActiveRecord::Migration[7.0]
  def change
    add_column :my_modules, :notification_sent, :boolean, default: false
  end
end
