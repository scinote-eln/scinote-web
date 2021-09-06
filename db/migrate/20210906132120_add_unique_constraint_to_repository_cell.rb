# frozen_string_literal: true

class AddUniqueConstraintToRepositoryCell < ActiveRecord::Migration[6.1]
  def change
    add_index :repository_cells,
              %i(repository_row_id repository_column_id),
              name: 'index_repository_cells_on_repository_row_and_repository_column',
              unique: true
  end
end
