# frozen_string_literal: true

class AddRepositoryRowCodeIndex < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_repository_rows_on_repository_row_code ON "\
      "repository_rows using gin (('IT'::text || id) gin_trgm_ops);"
    )
  end

  def down
    remove_index :repository_rows, name: 'index_repository_rows_on_repository_row_code'
  end
end
