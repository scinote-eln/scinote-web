class AddForeignKeys < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :my_modules, :my_module_groups
    add_foreign_key :project_comments, :comments
    add_foreign_key :my_module_comments, :comments
    add_foreign_key :result_assets, :results
    add_foreign_key :result_comments, :comments
    add_foreign_key :checklist_items, :checklists
  end
end
