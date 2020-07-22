# frozen_string_literal: true

class AddOtpRecoveryCodesToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table :users, bulk: true do |t|
      t.jsonb :otp_recovery_codes
    end
  end
end
