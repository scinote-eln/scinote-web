class CreateAssets < ActiveRecord::Migration[4.2]
  def change
    create_table :assets do |t|

      t.timestamps null: false
    end
    add_index :assets, :created_at
  end
end
