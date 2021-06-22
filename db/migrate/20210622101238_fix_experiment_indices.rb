# frozen_string_literal: true

class FixExperimentIndices < ActiveRecord::Migration[6.1]
  def up
    remove_index :experiments, name: 'index_experiments_on_name', column: 'name'

    ActiveRecord::Base.connection.execute(
      'CREATE INDEX index_experiments_on_name ON experiments using gin (trim_html_tags(name) gin_trgm_ops);'
    )

    ActiveRecord::Base.connection.execute(
      'CREATE INDEX index_experiments_on_description ON experiments ' \
      'using gin (trim_html_tags(description) gin_trgm_ops);'
    )
  end

  def down
    ActiveRecord::Base.connection.execute(
      'DROP INDEX index_experiments_on_name;'
    )

    ActiveRecord::Base.connection.execute(
      'DROP INDEX index_experiments_on_description;'
    )

    add_index :experiments, :name
  end
end
