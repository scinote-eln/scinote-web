# frozen_string_literal: true

class AddErrorInfoToWebhooksAndRenameMethodColumn < ActiveRecord::Migration[6.1]
  def change
    change_table :webhooks, bulk: true do |t|
      t.integer :error_count, default: 0, null: false
      t.text :last_error, :text
      t.rename :method, :http_method
    end
  end
end
