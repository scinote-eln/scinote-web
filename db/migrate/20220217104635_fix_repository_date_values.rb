# frozen_string_literal: true

class FixRepositoryDateValues < ActiveRecord::Migration[6.1]
  def up
    add_column :repository_date_time_values, :data_dup, :datetime
    change_table :repository_date_time_range_values, bulk: true do |t|
      t.datetime :start_time_dup
      t.datetime :end_time_dup
    end

    ActiveRecord::Base.connection.execute('UPDATE repository_date_time_values SET data_dup = data;')
    ActiveRecord::Base.connection.execute('UPDATE repository_date_time_range_values SET start_time_dup = start_time;')
    ActiveRecord::Base.connection.execute('UPDATE repository_date_time_range_values SET end_time_dup = end_time;')

    ActiveRecord::Base.connection.execute(
      "UPDATE repository_date_time_values SET data =
        (CASE WHEN EXTRACT(HOUR FROM data) > 12 THEN
          data::date + INTERVAL '1' DAY
        ELSE
          data::date
        END)
       WHERE type='RepositoryDateValue';"
    )
    ActiveRecord::Base.connection.execute(
      "UPDATE repository_date_time_range_values SET start_time =
        (CASE WHEN EXTRACT(HOUR FROM start_time) > 12 THEN
          start_time::date + INTERVAL '1' DAY
        ELSE
          start_time::date
        END)
       WHERE type='RepositoryDateRangeValue';"
    )
    ActiveRecord::Base.connection.execute(
      "UPDATE repository_date_time_range_values SET end_time =
        (CASE WHEN EXTRACT(HOUR FROM end_time) > 12 THEN
          end_time::date + INTERVAL '1' DAY
        ELSE
          end_time::date
        END)
       WHERE type='RepositoryDateRangeValue';"
    )
  end

  def down
    change_table :repository_date_time_range_values, bulk: true do |t|
      t.remove :end_time_dup
      t.remove :start_time_dup
    end
    remove_column :repository_date_time_values, :data_dup
  end
end
