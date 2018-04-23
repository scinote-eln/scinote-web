class CreateRapProjectLevels < ActiveRecord::Migration[5.1]
  def change
    create_table :rap_project_levels do |t|
      t.string :name, null: false
      t.references :rap_topic_level, foreign_key: true

      t.timestamps
    end
    add_index :rap_project_levels, unique: true
  end
end
