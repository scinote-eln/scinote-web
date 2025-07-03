class AddCounterCacheToSamples < ActiveRecord::Migration[4.2]
  def up
    add_column :samples, :nr_of_modules_assigned_to, :integer, default: 0
    add_column :my_modules, :nr_of_assigned_samples, :integer, default: 0
  end

  def down
    remove_column :samples, :nr_of_modules_assigned_to
    remove_column :my_modules, :nr_of_assigned_samples
  end
end
