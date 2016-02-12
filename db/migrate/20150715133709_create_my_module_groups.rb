class CreateMyModuleGroups < ActiveRecord::Migration
  def change
    create_table :my_module_groups do |t|
      t.string :name, null: false

      t.timestamps null: false
    end
  end
end
