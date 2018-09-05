class AddTooltipsEnabledToUserSettings < ActiveRecord::Migration[5.1]
  def up
    User.find_each do |user|
      user.settings[:tooltips_enabled] = true
      user.save
    end
  end

  def down
    User.find_each do |user|
      user.settings.delete(:tooltips_enabled)
      user.save
    end
  end
end
