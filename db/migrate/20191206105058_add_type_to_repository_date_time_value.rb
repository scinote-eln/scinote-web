# frozen_string_literal: true

class AddTypeToRepositoryDateTimeValue < ActiveRecord::Migration[6.0]
  def change
    add_column :repository_date_time_values, :type, :string
    add_column :repository_date_time_range_values, :type, :string
  end
end
