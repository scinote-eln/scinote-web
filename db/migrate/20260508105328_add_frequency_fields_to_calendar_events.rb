class AddFrequencyFieldsToCalendarEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :calendar_events, :frequency, :string
    add_column :calendar_events, :interval, :integer
    add_column :calendar_events, :interval_unit, :string
    add_column :calendar_events, :repeat_count, :integer
    add_column :calendar_events, :repeat_until, :datetime
  end
end
