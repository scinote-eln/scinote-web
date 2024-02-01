# frozen_string_literal: true

class CreateAssetSyncTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :asset_sync_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.references :asset, null: false, foreign_key: true
      t.string :token, index: { unique: true }
      t.timestamp :expires_at
      t.timestamp :revoked_at

      t.timestamps
    end
  end
end
