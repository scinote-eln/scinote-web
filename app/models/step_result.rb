# frozen_string_literal: true

class StepResult < ApplicationRecord
  belongs_to :result, class_name: 'ResultBase'
  belongs_to :step
  belongs_to :created_by, class_name: 'User'
end
