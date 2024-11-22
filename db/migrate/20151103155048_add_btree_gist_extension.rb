require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddBtreeGistExtension < ActiveRecord::Migration[4.2]
  def up
    enable_extension :btree_gist
  end
end
