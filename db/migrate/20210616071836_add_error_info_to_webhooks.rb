# frozen_string_literal: true

class AddErrorInfoToWebhooks < ActiveRecord::Migration[6.1]
  def change
    add_column :webhooks, :error_count, :integer, default: 0, null: false
    add_column :webhooks, :last_error, :text
  end
end
