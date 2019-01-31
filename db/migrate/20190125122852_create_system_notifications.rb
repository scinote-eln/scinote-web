# frozen_string_literal: true

class CreateSystemNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :system_notifications do |t|
      t.string :title
      t.text :description
      t.string :modal_title
      t.text :modal_body
      t.boolean :show_on_login, default: false
      t.datetime :source_created_at, index: true
      t.bigint :source_id, index: true, unique: true
      t.datetime :last_time_changed_at, index: true, null: false

      t.timestamps
    end
  end
end
