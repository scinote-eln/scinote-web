class AddDefaultColumnsToSamples < ActiveRecord::Migration[4.2]
  def change
    add_column :samples, :sample_group_id, :integer
    add_column :samples, :sample_type_id, :integer

    add_foreign_key :samples, :sample_groups
    add_foreign_key :samples, :sample_types
    add_index :samples, :sample_group_id
    add_index :samples, :sample_type_id
  end
end
