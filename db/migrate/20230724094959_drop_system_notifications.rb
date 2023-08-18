# frozen_string_literal: true

class DropSystemNotifications < ActiveRecord::Migration[7.0]
  def up
    drop_table :user_system_notifications
    drop_table :system_notifications
  end
end
