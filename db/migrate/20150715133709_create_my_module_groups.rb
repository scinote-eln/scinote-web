class CreateMyModuleGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :my_module_groups do |t|
      t.string :name, null: false

      t.timestamps null: false
    end
  end
end
