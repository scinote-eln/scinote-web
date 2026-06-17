class AddDateFieldsToCalendartEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :calendar_events, :start_date, :date
    add_column :calendar_events, :end_date, :date
    rename_column :calendar_events, :start_at, :start_datetime
    rename_column :calendar_events, :end_at, :end_datetime

    remove_column :calendar_events, :full_day, :boolean, default: false
  end
end
