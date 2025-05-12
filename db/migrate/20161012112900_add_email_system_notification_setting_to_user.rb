class AddEmailSystemNotificationSettingToUser < ActiveRecord::Migration[4.2]
  class TempUser < ApplicationRecord
    self.table_name = 'users'
  end

  def up
    add_column :users,
               :system_message_notification_email,
               :boolean,
               default: false

    TempUser.update_all(system_message_notification_email: false)
  end

  def down
    remove_column :users, :system_message_notification_email
  end
end
