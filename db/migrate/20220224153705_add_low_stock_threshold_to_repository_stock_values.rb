# frozen_string_literal: true

class AddLowStockThresholdToRepositoryStockValues < ActiveRecord::Migration[6.1]
  def change
    add_column :repository_stock_values, :low_stock_threshold, :decimal
  end
end
