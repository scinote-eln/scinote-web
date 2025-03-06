# frozen_string_literal: true

class RemovePositionIndexFromResultsOrderableElement < ActiveRecord::Migration[7.0]
  def change
    remove_index :result_orderable_elements, %i(result_id position)
  end
end
