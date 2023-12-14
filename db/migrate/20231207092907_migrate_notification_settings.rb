# frozen_string_literal: true

class MigrateNotificationSettings < ActiveRecord::Migration[7.0]
  def up
    User.find_each do |user|
      user.settings[:notifications_settings] =
        user.settings[:notifications_settings].merge(Extends::DEFAULT_USER_NOTIFICATION_SETTINGS)

      user.settings[:notifications_settings][:project_experiment_access] = {
        in_app: user.settings.dig(:notifications_settings, :assignments),
        email: user.settings.dig(:notifications_settings, :assignments_email)
      }

      user.settings[:notifications_settings][:other_team_invitation] = {
        in_app: user.settings.dig(:notifications_settings, :assignments),
        email: user.settings.dig(:notifications_settings, :assignments_email)
      }

      user.save!
    end
  end

  def down; end
end
