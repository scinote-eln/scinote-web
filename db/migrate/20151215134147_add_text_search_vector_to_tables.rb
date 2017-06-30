require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddTextSearchVectorToTables < ActiveRecord::Migration[4.2]
  def change
    add_column :tables, :data_vector, :tsvector

    if db_adapter_is? "PostgreSQL" then
      add_index :tables, :data_vector, using: "gin"
    end
  end
end
