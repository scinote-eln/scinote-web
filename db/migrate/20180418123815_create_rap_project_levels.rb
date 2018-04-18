class CreateRapProjectLevels < ActiveRecord::Migration[5.1]
  def change
    create_table :rap_project_levels do |t|
      t.string :name
      t.references :rap_topic_level, foreign_key: true

      t.timestamps
    end
  end
end
