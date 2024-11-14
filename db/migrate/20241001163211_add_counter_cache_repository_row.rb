# frozen_string_literal: true

class AddCounterCacheRepositoryRow < ActiveRecord::Migration[7.0]
  def change
    change_table :repositories, bulk: true do |t|
      t.integer :repository_rows_count, default: 0, null: false
    end

    Repository.find_each do |repository|
      Repository.reset_counters(repository.id, :repository_rows)
    end
  end
end
