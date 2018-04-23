class CreateRapProgramLevels < ActiveRecord::Migration[5.1]
  def change
    create_table :rap_program_levels do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :rap_program_levels, :name, unique: true
  end
end
