class CreateRapTaskLevels < ActiveRecord::Migration[5.1]
  def change
    create_table :rap_task_levels do |t|
      t.string :name
      t.references :rap_project_level, foreign_key: true

      t.timestamps
    end
  end
end
