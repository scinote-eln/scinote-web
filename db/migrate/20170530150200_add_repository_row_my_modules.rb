class AddRepositoryRowMyModules < ActiveRecord::Migration
  def change
    create_table :repository_row_my_modules do |t|
      t.belongs_to :repository_row, index: true
      t.belongs_to :my_module, index: true
      t.integer :assigned_by_id, null: false
      t.timestamps null: true
    end

    add_foreign_key :repository_row_my_modules, :users, column: :assigned_by_id
  end
end
