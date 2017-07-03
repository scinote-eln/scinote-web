class CreateLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :logs do |t|
      t.integer :team_id, null: false
      t.string :message, null: false
    end
    add_foreign_key :logs, :teams
  end
end
