# frozen_string_literal: true

class RemoveDelimiterFromRepositoryColumn < ActiveRecord::Migration[6.0]
  def change
    remove_column :repository_columns, :delimiter, :string
  end
end
