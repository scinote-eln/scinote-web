# frozen_string_literal: true

class AddSecretKeyToWebhooks < ActiveRecord::Migration[6.1]
  def change
    add_column :webhooks, :secret_key, :string
  end
end
