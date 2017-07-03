class CreateSamples < ActiveRecord::Migration[4.2]
  def change
    create_table :samples do |t|
      t.string :name, null: false

      # Foreign keys
      t.integer :user_id, null: false
      t.integer :team_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :samples, :users
    add_foreign_key :samples, :teams
    add_index :samples, :user_id
    add_index :samples, :team_id
  end
end
