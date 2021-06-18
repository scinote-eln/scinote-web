# frozen_string_literal: true

class AddCodeIndexToExperiments < ActiveRecord::Migration[6.1]
  def change
    add_index :experiments, "('EX' || id)", name: 'index_experiments_on_experiment_code', unique: true
  end
end
