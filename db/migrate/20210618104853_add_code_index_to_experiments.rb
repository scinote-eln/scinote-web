# frozen_string_literal: true

class AddCodeIndexToExperiments < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_experiments_on_experiment_code ON experiments using gin (('EX'::text || id) gin_trgm_ops);"
    )
  end

  def down
    ActiveRecord::Base.connection.execute(
      'DROP INDEX index_experiments_on_experiment_code;'
    )
  end
end
