# frozen_string_literal: true

class AddDiscardedAtAndDiscardedByToRepositoryRows < ActiveRecord::Migration[7.2]
  def change
    add_column :repository_rows, :discarded_at, :datetime
    add_index :repository_rows, :discarded_at
  end
end
