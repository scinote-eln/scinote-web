class CreateTempFiles < ActiveRecord::Migration
  def change
    create_table :temp_files do |t|
      t.string :session_id, null: false

      t.timestamps null: false
    end
    add_attachment :temp_files, :file
  end
end
