# frozen_string_literal: true

class Add2faToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table :users, bulk: true do |t|
      t.boolean :two_factor_auth_enabled, default: false, null: false
      t.string :otp_secret
    end
  end
end
