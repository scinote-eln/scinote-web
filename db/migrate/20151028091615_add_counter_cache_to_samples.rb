class AddCounterCacheToSamples < ActiveRecord::Migration[4.2]
  class TempMyModule < ApplicationRecord
    self.table_name = 'my_modules'

    has_many :sample_my_modules, foreign_key: :my_module_id
  end

  def up
    add_column :samples, :nr_of_modules_assigned_to, :integer, default: 0
    add_column :my_modules, :nr_of_assigned_samples, :integer, default: 0

    # Okay, now initialize the values
    if defined?(Sample)
      Sample.find_each do |sample|
        Sample.reset_counters(sample.id, :sample_my_modules)
      end

      TempMyModule.find_each do |my_module|
        TempMyModule.reset_counters(my_module.id, :sample_my_modules)
      end
    end
  end

  def down
    remove_column :samples, :nr_of_modules_assigned_to
    remove_column :my_modules, :nr_of_assigned_samples
  end
end
