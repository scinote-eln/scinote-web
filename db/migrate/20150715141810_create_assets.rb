class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|

      t.timestamps null: false
    end
    add_attachment :assets, :file
    add_index :assets, :created_at
  end
end
