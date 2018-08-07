class DeleteSamplesAndAssociatedModels < ActiveRecord::Migration[5.1]
  def change
    drop_table :samples_tables
    drop_table :sample_custom_fields
    drop_table :sample_my_modules
    drop_table :samples
    drop_table :sample_types
    drop_table :sample_groups
  end
end
