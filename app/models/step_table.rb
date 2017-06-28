class StepTable < ApplicationRecord
  validates :step, :table, presence: true

  belongs_to :step, inverse_of: :step_tables, optional: true
  belongs_to :table, inverse_of: :step_table, optional: true
end
