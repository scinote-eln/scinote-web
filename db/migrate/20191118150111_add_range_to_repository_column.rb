# frozen_string_literal: true

class AddRangeToRepositoryColumn < ActiveRecord::Migration[6.0]
  def change
    add_column :repository_columns, :range, :boolean
  end
end
