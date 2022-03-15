# frozen_string_literal: true

class AddDateTimeIndicesToRepositories < ActiveRecord::Migration[6.1]
  def up
    remove_index :repository_date_time_range_values, :start_time
    remove_index :repository_date_time_range_values, :end_time

    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_rows_on_created_at_as_date_time_minutes" '\
      'ON "repository_rows" (date_trunc(\'minute\', "created_at"));'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_rows_on_archived_on_as_date_time_minutes" '\
      'ON "repository_rows" (date_trunc(\'minute\', "archived_on"));'
    )

    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_date_time_values_on_data_as_time" '\
      'ON "repository_date_time_values" (CAST("data" AS TIME)) WHERE "type" = \'RepositoryTimeValue\';'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_date_time_values_on_data_as_date" '\
      'ON "repository_date_time_values" (CAST("data" AS DATE)) WHERE "type" = \'RepositoryDateValue\';'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_date_time_values_on_data_as_date_time" '\
      'ON "repository_date_time_values" ("data") WHERE "type" = \'RepositoryDateTimeValue\';'
    )

    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_date_time_range_values_on_start_time_as_time" '\
      'ON "repository_date_time_range_values" (CAST("start_time" AS TIME)) WHERE "type" = \'RepositoryTimeRangeValue\';'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_date_time_range_values_on_end_time_as_time" '\
      'ON "repository_date_time_range_values" (CAST("end_time" AS TIME)) WHERE "type" = \'RepositoryTimeRangeValue\';'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_date_time_range_values_on_start_time_as_date" '\
      'ON "repository_date_time_range_values" (CAST("start_time" AS DATE)) WHERE "type" = \'RepositoryDateRangeValue\';'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_date_time_range_values_on_end_time_as_date" '\
      'ON "repository_date_time_range_values" (CAST("end_time" AS DATE)) WHERE "type" = \'RepositoryDateRangeValue\';'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_date_time_range_values_on_start_time_as_date_time" '\
      'ON "repository_date_time_range_values" ("start_time") WHERE "type" = \'RepositoryDateTimeRangeValue\';'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE INDEX "index_repository_date_time_range_values_on_end_time_as_date_time" '\
      'ON "repository_date_time_range_values" ("end_time") WHERE "type" = \'RepositoryDateTimeRangeValue\';'
    )
  end

  def down
    ActiveRecord::Base.connection.execute(
      'DROP INDEX "index_repository_date_time_range_values_on_end_time_as_date_time";'
    )
    ActiveRecord::Base.connection.execute(
      'DROP INDEX "index_repository_date_time_range_values_on_start_time_as_date_time";'
    )
    ActiveRecord::Base.connection.execute(
      'DROP INDEX "index_repository_date_time_range_values_on_end_time_as_date";'
    )
    ActiveRecord::Base.connection.execute(
      'DROP INDEX "index_repository_date_time_range_values_on_start_time_as_date";'
    )
    ActiveRecord::Base.connection.execute(
      'DROP INDEX "index_repository_date_time_range_values_on_end_time_as_time";'
    )
    ActiveRecord::Base.connection.execute(
      'DROP INDEX "index_repository_date_time_range_values_on_start_time_as_time";'
    )

    ActiveRecord::Base.connection.execute('DROP INDEX "index_repository_date_time_values_on_data_as_date_time";')
    ActiveRecord::Base.connection.execute('DROP INDEX "index_repository_date_time_values_on_data_as_date";')
    ActiveRecord::Base.connection.execute('DROP INDEX "index_repository_date_time_values_on_data_as_time";')

    ActiveRecord::Base.connection.execute('DROP INDEX "index_repository_rows_on_archived_on_as_date_time_minutes";')
    ActiveRecord::Base.connection.execute('DROP INDEX "index_repository_rows_on_created_at_as_date_time_minutes";')

    add_index :repository_date_time_range_values, :end_time
    add_index :repository_date_time_range_values, :start_time
  end
end
