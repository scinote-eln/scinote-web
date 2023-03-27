# frozen_string_literal: true

class AddIndexToExperiments < ActiveRecord::Migration[6.1]
  def change
    add_index :experiments, :archived
  end
end
