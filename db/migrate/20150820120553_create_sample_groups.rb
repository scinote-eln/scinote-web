class CreateSampleGroups < ActiveRecord::Migration
  def change
    create_table :sample_groups do |t|
      t.string :name, null: false
      t.string :color, null: false, default: "#ff0000"

      t.integer :organization_id, null: false
      t.timestamps null: false
    end
    add_foreign_key :sample_groups, :organizations
    add_index :sample_groups, :organization_id
  end
end
