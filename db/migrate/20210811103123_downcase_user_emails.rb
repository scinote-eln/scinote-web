# frozen_string_literal: true

class DowncaseUserEmails < ActiveRecord::Migration[6.1]
  def up
    execute('UPDATE users SET email = LOWER(email)')
  end
end
