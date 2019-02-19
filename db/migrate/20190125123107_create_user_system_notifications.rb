# frozen_string_literal: true

class CreateUserSystemNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :user_system_notifications do |t|
      t.references :user, foreign_key: true
      t.references :system_notification, foreign_key: true
      t.datetime :seen_at, index: true
      t.datetime :read_at, index: true

      t.timestamps
    end
  end
end
