class RefreshAssignedSamplesCounters < ActiveRecord::Migration[4.2]
  def up
    # Reset the counters for assigned samples
    if defined?(Sample)
      Sample.find_each do |sample|
        sample.update(nr_of_modules_assigned_to: sample.my_modules.count)
      end

      MyModule.find_each do |my_module|
        my_module.update(nr_of_assigned_samples: my_module.samples.count)
      end
    end
  end
end
