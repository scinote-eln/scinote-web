class AddEmailNotificationSettingsToUser < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :assignments_notification_email, :boolean, default: false
    add_column :users, :recent_notification_email, :boolean, default: false
  end

  def down
    remove_column :users, :assignments_notification_email
    remove_column :users, :recent_notification_email
  end
end
