# frozen_string_literal: true

class StepTable < ApplicationRecord
  belongs_to :step, inverse_of: :step_tables, touch: true
  belongs_to :table, inverse_of: :step_table
  has_one :step_orderable_element, as: :orderable, dependent: :destroy
end
