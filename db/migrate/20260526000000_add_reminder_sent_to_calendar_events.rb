# frozen_string_literal: true

class AddReminderSentToCalendarEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :calendar_events, :reminder_sent, :boolean, default: false, null: false
  end
end
