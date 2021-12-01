# frozen_string_literal: true

class Connection < ApplicationRecord
  belongs_to :to, class_name: 'MyModule', foreign_key: 'input_id', inverse_of: :inputs
  belongs_to :from, class_name: 'MyModule', foreign_key: 'output_id', inverse_of: :outputs

  validate :ensure_non_cyclical

  private

  def ensure_non_cyclical
    connections = Connection.where(
      input_id: to.experiment.my_modules.select(:id)
    ).pluck(:input_id, :output_id).to_h

    visited_nodes = [output_id]

    current_input_id = output_id

    while (current_input_id = connections[current_input_id])
      if current_input_id == input_id || visited_nodes.include?(current_input_id)
        errors.add(:output_id, :creates_cycle) and return
      end

      visited_nodes.push(current_input_id)
    end
  end
end
