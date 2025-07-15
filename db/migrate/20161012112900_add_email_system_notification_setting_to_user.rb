class AddEmailSystemNotificationSettingToUser < ActiveRecord::Migration[4.2]
  def up
    add_column :users,
               :system_message_notification_email,
               :boolean,
               default: false
  end

  def down
    remove_column :users, :system_message_notification_email
  end
end
