class CreateSampleCustomFields < ActiveRecord::Migration[4.2]
  def change
    create_table :sample_custom_fields do |t|
      t.string :value, null: false

      t.integer :custom_field_id, null: false
      t.integer :sample_id, null: :false

      t.timestamps null: false
    end
    add_foreign_key :sample_custom_fields, :custom_fields
    add_foreign_key :sample_custom_fields, :samples

    add_index :sample_custom_fields, :custom_field_id
    add_index :sample_custom_fields, :sample_id
  end
end
