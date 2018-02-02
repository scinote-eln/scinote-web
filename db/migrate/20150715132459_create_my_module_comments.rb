class CreateMyModuleComments < ActiveRecord::Migration[4.2]
  def change
    create_table :my_module_comments do |t|
      t.integer :my_module_id, null: false
      t.integer :comment_id, null: false
    end
    add_foreign_key :my_module_comments, :my_modules
    add_index :my_module_comments, [:my_module_id, :comment_id]
  end
end
