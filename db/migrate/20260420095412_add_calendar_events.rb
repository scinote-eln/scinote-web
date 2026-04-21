# frozen_string_literal: true

class AddCalendarEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :calendar_events do |t|
      t.references :subject, polymorphic: true, null: false
      t.references :team, null: false, foreign_key: true
      t.datetime :start_at
      t.datetime :end_at
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :event_type, null: false, index: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :calendar_event_participants do |t|
      t.references :calendar_event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :calendar_event_participants, %i(calendar_event_id user_id), unique: true
  end
end
