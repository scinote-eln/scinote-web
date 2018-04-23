class CreateRapTopicLevels < ActiveRecord::Migration[5.1]
  def change
    create_table :rap_topic_levels do |t|
      t.string :name, null: false
      t.references :rap_program_level, foreign_key: true

      t.timestamps
    end
    add_index :rap_topic_levels, :name, unique: true
  end
end
