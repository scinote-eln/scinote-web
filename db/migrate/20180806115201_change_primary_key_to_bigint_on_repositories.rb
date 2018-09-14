# frozen_string_literal: true

class ChangePrimaryKeyToBigintOnRepositories < ActiveRecord::Migration[5.1]
  def up
    change_column :repository_rows, :id, :bigint
    change_column :repository_columns, :id, :bigint
    change_column :repository_cells, :id, :bigint
    change_column :repository_cells, :repository_row_id, :bigint
    change_column :repository_cells, :value_id, :bigint
    change_column :repository_text_values, :id, :bigint
    change_column :repository_date_values, :id, :bigint
    change_column :my_module_repository_rows, :repository_row_id, :bigint
  end

  def down
    change_column :repository_rows, :id, :integer
    change_column :repository_columns, :id, :integer
    change_column :repository_cells, :id, :integer
    change_column :repository_cells, :repository_row_id, :integer
    change_column :repository_cells, :value_id, :integer
    change_column :repository_text_values, :id, :integer
    change_column :repository_date_values, :id, :integer
    change_column :my_module_repository_rows, :repository_row_id, :integer
  end
end
