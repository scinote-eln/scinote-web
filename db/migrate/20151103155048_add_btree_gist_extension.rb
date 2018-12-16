require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddBtreeGistExtension < ActiveRecord::Migration[4.2]
  def up
    if db_adapter_is? "PostgreSQL" then
      enable_extension :btree_gist
    end
  end
end
