module DatabaseHelper
  # Check if database adapter equals to the specified name
  def db_adapter_is?(adapter_name)
    ActiveRecord::Base.connection.adapter_name == adapter_name
  end

  # Create gist trigram index. PostgreSQL only!
  def add_gist_index(table, column)
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_#{table}_on_#{column} ON " \
      "#{table} USING gist (#{column} gist_trgm_ops);"
    )
  end

  # Create gin trigram index with filtered out html tags. PostgreSQL only!
  def add_gin_index_without_tags(table, column)
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_#{table}_on_#{column} ON " \
      "#{table} USING gin ((trim_html_tags(#{column})) gin_trgm_ops);"
    )
  end

  # Create gin trigram index with filtered out html tags. PostgreSQL only!
  def add_gin_index_for_numbers(table, column)
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_#{table}_on_#{column}_text ON " \
      "#{table} USING gin (((#{column})::text) gin_trgm_ops);"
    )
  end

  def remove_gin_index_for_numbers(table, column)
    ActiveRecord::Base.connection.execute(
      "DROP INDEX IF EXISTS index_#{table}_on_#{column}_text;"
    )
  end

  # Get size of whole table & its indexes
  # (in bytes). PostgreSQL only!
  def get_table_size(table)
    ActiveRecord::Base.connection.execute(
      "SELECT pg_total_relation_size('#{table}');"
    ).getvalue(0, 0).to_i
  end

  # Get octet length (in bytes) of given column
  # of specified SINGLE ActiveRecord. PostgreSQL only!
  def get_octet_length_record(object, column)
    get_octet_length(
      object.class.to_s.tableize,
      column,
      object.id
    )
  end

  # Get octet length (in bytes) of given column
  # in table for specific id. PostgreSQL only!
  def get_octet_length(table, column, id)
    ActiveRecord::Base.connection.execute(
      "SELECT octet_length(cast(t.#{column} as text)) FROM #{table} " \
      "AS t WHERE t.id = #{id};"
    ).getvalue(0, 0).to_i
  end

  # Adds a check constraint to the table
  def add_check_constraint(table, constraint_name, constraint)
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE " \
      "#{table} " \
      "DROP CONSTRAINT IF EXISTS #{constraint_name}, " \
      "ADD CONSTRAINT " \
      "#{constraint_name} " \
      "CHECK ( #{constraint} ) " \
      "not valid;"
    )
  end

  # Remove constraint from the table
  def drop_constraint(table, constraint_name)
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE " \
      "#{table} " \
      "DROP CONSTRAINT IF EXISTS #{constraint_name}; "
    )
  end
end
