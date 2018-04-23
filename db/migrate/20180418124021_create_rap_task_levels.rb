class CreateRapTaskLevels < ActiveRecord::Migration[5.1]
  def change
    create_table :rap_task_levels do |t|
      t.string :name, null: false
      t.references :rap_project_level, foreign_key: true

      t.timestamps
    end
    add_index :rap_task_levels, :name, unique: true
  end
end
