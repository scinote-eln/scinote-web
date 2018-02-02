class CreateUserOrganizations < ActiveRecord::Migration[4.2]
  def change
    create_table :user_teams do |t|
      t.column :role, :integer, null: false, default: 1
      t.integer :user_id, null: false
      t.integer :team_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :user_teams, :users
    add_foreign_key :user_teams, :teams
  end
end
