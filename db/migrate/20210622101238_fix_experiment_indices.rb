# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class FixExperimentIndices < ActiveRecord::Migration[6.1]
  include DatabaseHelper

  def up
    remove_index :experiments, name: 'index_experiments_on_name', column: 'name'

    add_gin_index_without_tags(:experiments, :name)
    add_gin_index_without_tags(:experiments, :description)

    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_experiments_on_experiment_code ON experiments using gin (('EX'::text || id) gin_trgm_ops);"
    )
  end

  def down
    remove_index :experiments, name: 'index_experiments_on_experiment_code'
    remove_index :experiments, name: 'index_experiments_on_description'
    remove_index :experiments, name: 'index_experiments_on_name'

    add_index :experiments, :name
  end
end
