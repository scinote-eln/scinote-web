# frozen_string_literal: true

class RenameWebhookMethodColumn < ActiveRecord::Migration[6.1]
  def change
    rename_column :webhooks, :method, :http_method
  end
end
