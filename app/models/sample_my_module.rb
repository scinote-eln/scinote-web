class SampleMyModule < ActiveRecord::Base
  validates :sample, :my_module, presence: true

  # One sample can only be assigned once to a specific module
  validates_uniqueness_of :sample_id, :scope => :my_module_id

  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User'
  belongs_to :sample,
    inverse_of: :sample_my_modules,
    counter_cache: :nr_of_modules_assigned_to
  belongs_to :my_module,
    inverse_of: :sample_my_modules,
    counter_cache: :nr_of_assigned_samples
end
