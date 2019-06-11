# frozen_string_literal: true

class SampleMyModule < ApplicationRecord
  after_create :increment_nr_of_module_samples
  after_destroy :decrement_nr_of_module_samples

  validates :sample, :my_module, presence: true
  validates_uniqueness_of :sample_id, scope: :my_module_id

  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User', optional: true
  belongs_to :sample, inverse_of: :sample_my_modules
  belongs_to :my_module, inverse_of: :sample_my_modules

  def increment_nr_of_module_samples
    my_module.increment!(:nr_of_assigned_samples)
    sample.increment!(:nr_of_modules_assigned_to)
  end

  def decrement_nr_of_module_samples
    my_module.decrement!(:nr_of_assigned_samples)
    sample.decrement!(:nr_of_modules_assigned_to)
  end
end
