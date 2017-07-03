class CreateChecklists < ActiveRecord::Migration[4.2]
  def change
    create_table :checklists do |t|
      t.string :name, null: false
      t.integer :step_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :checklists, :steps
  end
end
