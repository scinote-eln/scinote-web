# frozen_string_literal: true

class StepTable < ApplicationRecord
  validates :step, :table, presence: true

  belongs_to :step, inverse_of: :step_tables, touch: true
  belongs_to :table, inverse_of: :step_table
end
