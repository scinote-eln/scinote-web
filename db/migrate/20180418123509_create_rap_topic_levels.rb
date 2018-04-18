class CreateRapTopicLevels < ActiveRecord::Migration[5.1]
  def change
    create_table :rap_topic_levels do |t|
      t.string :name
      t.references :rap_program_level, foreign_key: true

      t.timestamps
    end
  end
end
