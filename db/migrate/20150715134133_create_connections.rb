class CreateConnections < ActiveRecord::Migration[4.2]
  def change
    create_table :connections do |t|
      t.integer :input_id, null: false
      t.integer :output_id, null: false
    end
    add_foreign_key :connections, :my_modules, column: :input_id
    add_foreign_key :connections, :my_modules, column: :output_id
  end
end
