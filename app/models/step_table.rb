class StepTable < ActiveRecord::Base
  validates :step, :table, presence: true

  belongs_to :step, inverse_of: :step_tables
  belongs_to :table, inverse_of: :step_table
end
