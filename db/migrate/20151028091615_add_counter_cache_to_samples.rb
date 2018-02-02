class AddCounterCacheToSamples < ActiveRecord::Migration[4.2]
  def up
    add_column :samples, :nr_of_modules_assigned_to, :integer, :default => 0
    add_column :my_modules, :nr_of_assigned_samples, :integer, :default => 0

    # Okay, now initialize the values
    Sample.find_each do |sample|
      Sample.reset_counters(sample.id, :sample_my_modules)
    end

    MyModule.find_each do |my_module|
      MyModule.reset_counters(my_module.id, :sample_my_modules)
    end
  end

  def down
    remove_column :samples, :nr_of_modules_assigned_to
    remove_column :my_modules, :nr_of_assigned_samples
  end
end
