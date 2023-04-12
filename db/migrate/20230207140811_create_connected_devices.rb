# frozen_string_literal: true

class CreateConnectedDevices < ActiveRecord::Migration[6.1]
  def change
    create_table :connected_devices do |t|
      t.string :uid
      t.string :name
      t.references :oauth_access_token, null: false, foreign_key: true
      t.json :metadata
      t.timestamp :last_seen_at

      t.timestamps
    end
  end
end
