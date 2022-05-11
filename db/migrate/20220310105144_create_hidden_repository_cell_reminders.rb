# frozen_string_literal: true

class CreateHiddenRepositoryCellReminders < ActiveRecord::Migration[6.1]
  def change
    create_table :hidden_repository_cell_reminders do |t|
      t.references :repository_cell, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
