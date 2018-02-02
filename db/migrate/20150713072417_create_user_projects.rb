class CreateUserProjects < ActiveRecord::Migration[4.2]
  def change
    create_table :user_projects do |t|
      t.column :role, :integer, default: 0

      # Comment in spite of SQLite
      # t.integer :permissions, array: true, default: []

      t.integer :user_id, null: false
      t.integer :project_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :user_projects, :users
    add_foreign_key :user_projects, :projects
  end
end
