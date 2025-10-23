# frozen_string_literal: true

class StepResultTemplate < ApplicationRecord
  belongs_to :result_template
  belongs_to :step
  belongs_to :created_by, class_name: 'User'
end
