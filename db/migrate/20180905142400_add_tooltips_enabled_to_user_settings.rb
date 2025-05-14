class AddTooltipsEnabledToUserSettings < ActiveRecord::Migration[5.1]
  class TempUser < ApplicationRecord
    self.table_name = 'users'
  end

  def up
    TempUser.find_each do |user|
      user.settings[:tooltips_enabled] = true
      user.save
    end
  end

  def down
    TempUser.find_each do |user|
      user.settings.delete(:tooltips_enabled)
      user.save
    end
  end
end
