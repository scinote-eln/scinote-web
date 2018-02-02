class CreateSampleMyModules < ActiveRecord::Migration[4.2]
  def change
    create_table :sample_my_modules do |t|
      t.integer :sample_id, null: false
      t.integer :my_module_id, null: false
    end
    add_foreign_key :sample_my_modules, :samples
    add_foreign_key :sample_my_modules, :my_modules
    add_index :sample_my_modules, [:sample_id, :my_module_id]
  end
end
