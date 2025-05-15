class ResetAssignedSamplesCounters < ActiveRecord::Migration[4.2]
  class TempMyModule < ApplicationRecord
    self.table_name = 'my_modules'

    has_many :sample_my_modules, foreign_key: :my_module_id
  end

  def change
    if defined?(Sample)
      Sample.find_each do |sample|
        Sample.reset_counters(sample.id, :sample_my_modules)
      end

      TempMyModule.find_each do |my_module|
        TempMyModule.reset_counters(my_module.id, :sample_my_modules)
      end
    end
  end
end
