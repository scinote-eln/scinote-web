# frozen_string_literal: true

class AddApiKeyCreatedAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :api_key_created_at, :timestamp
  end
end
