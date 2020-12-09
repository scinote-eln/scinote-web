class CreateTempFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :temp_files do |t|
      t.string :session_id, null: false

      t.timestamps null: false
    end
  end
end
