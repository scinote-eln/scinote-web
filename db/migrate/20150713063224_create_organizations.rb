class CreateOrganizations < ActiveRecord::Migration[4.2]
  def change
    create_table :teams do |t|
      ## General info
      t.string :name, null: false

      t.timestamps null: false
    end
    add_index :teams, :name, unique: true
  end
end
