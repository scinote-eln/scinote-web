class CreateTables < ActiveRecord::Migration[4.2]
  def change
    create_table :tables do |t|
      t.binary :contents, null: false, limit: 20.megabyte

      t.timestamps null: false
    end
    add_index :tables, :created_at
  end
end
