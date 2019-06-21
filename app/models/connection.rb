# frozen_string_literal: true

class Connection < ApplicationRecord
  belongs_to :to, class_name: 'MyModule', foreign_key: 'input_id', inverse_of: :inputs
  belongs_to :from, class_name: 'MyModule', foreign_key: 'output_id', inverse_of: :outputs
end
