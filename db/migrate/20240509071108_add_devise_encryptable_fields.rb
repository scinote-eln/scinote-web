# frozen_string_literal: true

class AddDeviseEncryptableFields < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :password_salt, :string
  end
end
