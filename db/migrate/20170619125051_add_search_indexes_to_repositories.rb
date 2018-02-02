require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddSearchIndexesToRepositories < ActiveRecord::Migration[4.2]
  def up
    if db_adapter_is? 'PostgreSQL'
      if index_exists?(:repository_rows, :name)
        remove_index :repository_rows, :name
      end
      add_gin_index_without_tags :repository_rows, :name
      add_gin_index_without_tags :repository_text_values, :data
    end
  end

  def down
    if db_adapter_is? 'PostgreSQL'
      remove_index :repository_rows, :name
      remove_index :repository_text_values, :data
    end
  end
end
