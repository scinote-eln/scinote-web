class CreateReports < ActiveRecord::Migration[4.2]
  def change
    create_table :reports do |t|
      t.string :name, null: false
      t.string :description
      t.integer :grouped_by, null: false, default: 0

      t.integer :project_id, null: false
      t.integer :user_id, null: false

      t.timestamps null: false
    end

    add_foreign_key :reports, :projects
    add_index :reports, :project_id

    add_foreign_key :reports, :users
    add_index :reports, :user_id
  end
end
