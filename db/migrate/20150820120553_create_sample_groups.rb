class CreateSampleGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :sample_groups do |t|
      t.string :name, null: false
      t.string :color, null: false, default: '#ff0000'

      t.integer :team_id, null: false
      t.timestamps null: false
    end
    add_foreign_key :sample_groups, :teams
    add_index :sample_groups, :team_id
  end
end
