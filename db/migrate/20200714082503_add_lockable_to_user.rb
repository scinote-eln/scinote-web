# frozen_string_literal: true

class AddLockableToUser < ActiveRecord::Migration[6.0]
  def change
    change_table :users, bulk: true do |t|
      t.integer :failed_attempts, default: 0, null: false
      t.datetime :locked_at
      t.string :unlock_token, index: { unique: true }
    end
  end
end
