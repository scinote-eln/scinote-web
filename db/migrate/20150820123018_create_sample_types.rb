class CreateSampleTypes < ActiveRecord::Migration
  def change
    create_table :sample_types do |t|
      t.string :name, null: false

      t.integer :organization_id, null: false
      t.timestamps null: false
    end
    add_foreign_key :sample_types, :organizations
    add_index :sample_types, :organization_id
  end
end
