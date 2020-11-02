class ResetAssignedSamplesCounters < ActiveRecord::Migration[4.2]
  def change
    if defined?(Sample)
      Sample.find_each do |sample|
        Sample.reset_counters(sample.id, :sample_my_modules)
      end

      MyModule.find_each do |my_module|
        MyModule.reset_counters(my_module.id, :sample_my_modules)
      end
    end
  end
end
