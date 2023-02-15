# frozen_string_literal: true

class AddApiKeyToUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :api_key
      t.datetime :api_key_expires_at
    end
  end
end
