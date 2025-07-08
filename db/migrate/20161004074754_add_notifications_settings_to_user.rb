class AddNotificationsSettingsToUser < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :assignments_notification, :boolean, default: true
    add_column :users, :recent_notification, :boolean, default: true
  end

  def down
    remove_column :users, :assignments_notification
    remove_column :users, :recent_notification
  end
end
