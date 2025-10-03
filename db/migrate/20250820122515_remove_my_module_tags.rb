# frozen_string_literal: true

class RemoveMyModuleTags < ActiveRecord::Migration[7.2]
  def up
    drop_table :my_module_tags, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
