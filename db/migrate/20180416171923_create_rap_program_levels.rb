class CreateRapProgramLevels < ActiveRecord::Migration[5.1]
  def change
    create_table :rap_program_levels do |t|
      t.string :name

      t.timestamps
    end
  end
end
