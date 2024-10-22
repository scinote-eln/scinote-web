require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class GenerateTextSearchVectorForTableContents < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
    UPDATE tables
    SET data_vector =
      to_tsvector(substring(encode(contents::bytea, 'escape'), 9))
    SQL
  end
end
