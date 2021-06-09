# frozen_string_literal: true

class CreateWebhooksTable < ActiveRecord::Migration[6.0]
  def change
    create_table :webhooks do |t|
      t.references :activity_filter, null: false, index: true, foreign_key: true
      t.boolean :active, null: false, default: true
      t.string :url, null: false
      t.integer :method, null: false

      t.timestamps
    end
  end
end
