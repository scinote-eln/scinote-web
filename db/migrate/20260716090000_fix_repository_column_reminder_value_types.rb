# frozen_string_literal: true

class FixRepositoryColumnReminderValueTypes < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL.squish
      UPDATE repository_columns
      SET metadata = jsonb_set(metadata, '{reminder_value}', to_jsonb((metadata ->> 'reminder_value')), false)
      WHERE jsonb_typeof(metadata -> 'reminder_value') = 'number'
    SQL

    execute <<~SQL.squish
      UPDATE repository_columns
      SET metadata = jsonb_set(metadata, '{reminder_unit}', to_jsonb((metadata ->> 'reminder_unit')), false)
      WHERE jsonb_typeof(metadata -> 'reminder_unit') = 'number'
    SQL
  end
end
