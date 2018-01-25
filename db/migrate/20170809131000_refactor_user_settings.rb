class RefactorUserSettings < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :settings, :jsonb, default: {}, null: false

    User.find_each do |user|
      settings = {
        time_zone: user['time_zone'],
        notifications_settings: {
          assignments: user['assignments_notification'],
          assignments_email: user['assignments_notification_email'],
          recent: user['recent_notification'],
          recent_email: user['recent_notification_email'],
          system_message_email: user['system_message_notification_email']
        }
      }
      user.update(settings: settings)
    end

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

    User.find_each do |user|
      user.time_zone = user.settings[:time_zone]
      user.assignments_notification =
        user.settings[:notifications_settings][:assignments]
      user.assignments_notification_email =
        user.settings[:notifications_settings][:assignments_email]
      user.recent_notification =
        user.settings[:notifications_settings][:recent]
      user.recent_notification_email =
        user.settings[:notifications_settings][:recent_email]
      user.system_message_notification_email =
        user.settings[:notifications_settings][:system_message_email]
      user.save
    end

    remove_column :users, :settings, :jsonb
  end
end
