# frozen_string_literal: true
class AddIndexToRepositoryRows < ActiveRecord::Migration[6.1]
  def change
    add_index :repository_rows, :archived
  end
end
