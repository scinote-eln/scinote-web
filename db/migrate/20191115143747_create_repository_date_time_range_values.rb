# frozen_string_literal: true

class CreateRepositoryDateTimeRangeValues < ActiveRecord::Migration[6.0]
  def change
    create_table :repository_date_time_range_values do |t|
      t.datetime :start_time, index: true
      t.datetime :end_time, index: true
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }
      t.references :created_by, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    # rename existing table for consistency
    rename_table :repository_date_values, :repository_date_time_values
  end
end
