class AddNotificationsSettingsToUser < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :assignments_notification, :boolean, default: true
    add_column :users, :recent_notification, :boolean, default: true

    User.update_all(assignments_notification: true, recent_notification: true)
  end

  def down
    remove_column :users, :assignments_notification
    remove_column :users, :recent_notification
  end
end
