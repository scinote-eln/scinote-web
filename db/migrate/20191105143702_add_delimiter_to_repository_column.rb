# frozen_string_literal: true

class AddDelimiterToRepositoryColumn < ActiveRecord::Migration[6.0]
  def change
    add_column :repository_columns, :delimiter, :string
  end
end
