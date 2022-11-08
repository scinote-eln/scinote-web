# frozen_string_literal: true

class AddMyModuleCodeIndex < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_my_modules_on_my_module_code ON "\
      "my_modules using gin (('TA'::text || id) gin_trgm_ops);"
    )
  end

  def down
    remove_index :my_modules, name: 'index_my_modules_on_my_module_code'
  end
end
