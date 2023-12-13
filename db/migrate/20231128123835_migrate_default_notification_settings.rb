# frozen_string_literal: true

class MigrateDefaultNotificationSettings < ActiveRecord::Migration[7.0]
  def up
    User.find_each do |user|
      my_module_designation = user.settings.dig(:notifications_settings, :my_module_designation)

      next unless my_module_designation

      user.settings[:notifications_settings][:project_experiment_access] =
        {
          in_app: my_module_designation[:in_app],
          email: my_module_designation[:email]
        }
      user.settings[:notifications_settings][:other_team_invitation] =
        {
          in_app: my_module_designation[:in_app],
          email: my_module_designation[:email]
        }

      user.save!
    end
  end

  def down; end
end
