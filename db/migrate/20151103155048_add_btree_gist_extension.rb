require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddBtreeGistExtension < ActiveRecord::Migration[4.2]
  def up
    if db_adapter_is? "PostgreSQL" then
      create_extension :btree_gist
    end
  end

  def down
    if db_adapter_is? "PostgreSQL" then
      drop_extension :btree_gist
    end
  end
end
