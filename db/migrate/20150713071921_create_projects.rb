class CreateProjects < ActiveRecord::Migration[4.2]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.column :visibility, :integer, null: false, default: 0
      t.datetime :due_date
      t.integer :team_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :projects, :teams
  end
end
