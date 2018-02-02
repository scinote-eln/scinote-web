class CreateSampleTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :sample_types do |t|
      t.string :name, null: false

      t.integer :team_id, null: false
      t.timestamps null: false
    end
    add_foreign_key :sample_types, :teams
    add_index :sample_types, :team_id
  end
end
