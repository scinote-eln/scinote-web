# frozen_string_literal: true

class AddUniqueIndexToSystemNotifications < ActiveRecord::Migration[5.1]
  def change
    # remove not unique index and add new with uniq
    remove_index :system_notifications, :source_id
    add_index :system_notifications, :source_id, unique: true

    add_index :user_system_notifications, %i(user_id system_notification_id), unique: true,
              name: 'index_user_system_notifications_on_user_and_notification_id'
  end
end
