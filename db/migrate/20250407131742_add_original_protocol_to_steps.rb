# frozen_string_literal: true

class AddOriginalProtocolToSteps < ActiveRecord::Migration[7.0]
  def change
    add_reference :steps, :original_protocol, null: true, foreign_key: { to_table: :protocols }
  end
end
