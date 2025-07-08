class RefactorUserSettings < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :settings, :jsonb, default: {}, null: false

    remove_column :users, :time_zone, :string
    remove_column :users, :assignments_notification, :boolean
    remove_column :users, :assignments_notification_email, :boolean
    remove_column :users, :recent_notification, :boolean
    remove_column :users, :recent_notification_email, :boolean
    remove_column :users, :system_message_notification_email, :boolean
  end

  def down
    add_column :users, :time_zone, :string, default: false
    add_column :users, :assignments_notification, :boolean, default: false
    add_column :users, :assignments_notification_email, :boolean, default: false
    add_column :users, :recent_notification, :boolean, default: false
    add_column :users, :recent_notification_email, :boolean, default: false
    add_column :users,
               :system_message_notification_email, :boolean, default: false

    remove_column :users, :settings, :jsonb
  end
end
